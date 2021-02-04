describe 'sprint_client' do
  let(:query) do # needs this formatting so it matches the query in sprint_client.rb otherwise tests fail with incorrect spacing
    "mutation Print($printRequest: PrintRequest!, $printer: String!) {
      print(printRequest: $printRequest, printer: $printer) {
        jobId
      }
    }"
  end

  context 'get_template function' do
    it 'should get template when given a successful path' do
      dummy_path = 'spec/spec_config/label_templates/plate_96.yml.erb'

      template = SPrintClient.get_template(dummy_path)

      expect(template).to be_a(ERB)
    end

    it 'should return an error when given an incorrect path' do
      dummy_path = 'spec/spec_config/label_templates/plate_100.yml.erb'

      expect do
        SPrintClient.get_template(dummy_path)
      end.to raise_error('No such file or directory @ rb_sysopen - spec/spec_config/label_templates/plate_100.yml.erb')
    end
  end

  context 'send_post function' do
    context 'success' do
      it 'succesfully sends a post with the correct body and uri' do
        SPrintClient.sprint_uri = 'localhost'
        printer_name = 'test_name'
        response = SPrintClient.send_post({})
        expect(response.code).to eq '422'
      end
    end
  end

  context 'send_print_request function' do
    it 'should send a http with the correct body when called' do
      merge_fields_list = [{ barcode: 'DN111111', date: '1-APR-2020' }, { barcode: 'DN222222', date: '2-APR-2020' }]
      printer_name = 'test_name'
      label_template_name = 'test_label_name'

      allow(SPrintClient).to receive(:get_label_template_path).and_return('spec/spec_config/label_templates/plate_96.yml.erb')
      allow(SPrintClient).to receive(:set_layouts).and_return(['layouts_sets'])

      expect(SPrintClient).to receive(:get_label_template_path).with(label_template_name)
      expect(SPrintClient).to receive(:get_template).with('spec/spec_config/label_templates/plate_96.yml.erb')
      expect(SPrintClient).to receive(:set_layouts).with(merge_fields_list, nil)
      expect(SPrintClient).to receive(:send_post)
        .with({ query: query,
                variables: { printer: 'test_name', printRequest: { layouts: ['layouts_sets'] } } })

      SPrintClient.send_print_request(printer_name, label_template_name, merge_fields_list)
    end

    context 'when there is no label template' do
      it 'returns an 422 response' do
        merge_fields_list = [{ barcode: 'DN111111', date: '1-APR-2020' }, { barcode: 'DN222222', date: '2-APR-2020' }]
        printer_name = 'test_name'
        label_template_name = 'unknown'
        response = SPrintClient.send_print_request(printer_name, label_template_name, merge_fields_list)
        expect(response.code).to eq '422'
      end
    end
  end

  context 'set_layouts function' do
    it 'should parse the erb yaml file and return the right number of layouts' do
      dummy_path = 'spec/spec_config/label_templates/plate_96.yml.erb'
      template = SPrintClient.get_template(dummy_path)

      merge_fields_list = [
        { barcode: 'DN111111', date: '1-APR-2020' },
        { barcode: 'DN222222', date: '2-APR-2020' }
      ]

      layouts = SPrintClient.set_layouts(merge_fields_list, template)
      expect(layouts.length).to eq(4)
    end
  end
end
