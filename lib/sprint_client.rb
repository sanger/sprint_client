# frozen_string_literal: true

# Interfaces with SPrint service: https://github.com/sanger/sprint
class SPrintClient
  require 'uri'
  require 'erb'
  require 'yaml'
  require 'net/http'
  require 'json'

  # printer_name - a string showing which printer to send the request to
  # label_template_name - a string to identify which label template to be used in the print request e.g plate_384.yml.erb
  # merge_fields_list - a list of hashes, each containing the field values for a particular label
  #   e.g
  # [
  #  {"right_text"=>"DN9000003B", "left_text"=>"DN9000003B", "barcode"=>"DN9000003B", "extra_right_text"=>"DN9000003B  LTHR-384 RT", "extra_left_text"=>"10-NOV-2020"},
  #  {"right_text"=>"DN9000003B", "left_text"=>"DN9000003B", "barcode"=>"DN9000003B", "extra_right_text"=>"DN9000003B  LTHR-384 RT", "extra_left_text"=>"10-NOV-2020"}
  # ]
  #  would print two labels
  def self.send_print_request(printer_name, label_template_name, merge_fields_list)
    # define GraphQL print mutation
    query = "mutation Print($printRequest: PrintRequest!, $printer: String!) {
      print(printRequest: $printRequest, printer: $printer) {
        jobId
      }
    }"

    # locate the required label template
    path = get_label_template_path(label_template_name)
    begin
      template = get_template(path)
    rescue StandardError => e
      return Net::HTTPResponse.new('1.1', '422', "Could not find label template with name #{label_template_name}")
    end

    # parse the template for each label
    layouts = set_layouts(merge_fields_list, template)
    # layouts: [
    #   {
    #     "labelSize"=>{"width"=>68, "height"=>6, "displacement"=>13},
    #     "barcodeFields"=>[{"x"=>21, "y"=>0, "cellWidth"=>0.2, "barcodeType"=>"code39", "value"=>"DN9000003B", "height"=>5}],
    #     "textFields"=>[{"x"=>1, "y"=>4, "value"=>"DN9000003B", "font"=>"proportional", "fontSize"=>1.7}, {"x"=>47, "y"=>4, "value"=>"DN9000003B", "font"=>"proportional", "fontSize"=>1.7}]
    #   },
    #   {
    #     "labelSize"=>{"width"=>68, "height"=>6, "displacement"=>13},
    #     "textFields"=>[{"x"=>1, "y"=>3, "value"=>"10-NOV-2020", "font"=>"proportional", "fontSize"=>1.7}, {"x"=>15, "y"=>3, "value"=>"DN9000003B  LTHR-384 RT", "font"=>"proportional", "fontSize"=>1.7}]
    #   }
    # ]

    # build the body of the print request
    body = {
      "query": query,
      "variables": {
        "printer": printer_name,
        "printRequest": {
          "layouts": layouts
        }
      }
    }

    send_post(body)
  end

  def self.sprint_uri=(sprint_uri)
    @@sprint_uri = sprint_uri
  end

  def self.send_post(body)
    # send POST request to SPrint url and return response
    Net::HTTP.post URI(@@sprint_uri),
                   body.to_json,
                   'Content-Type' => 'application/json'
  rescue StandardError => e
    Net::HTTPResponse.new('1.1', '422', "Failed to send post to #{@@sprint_uri}")
  end

  def self.get_template(path)
    ERB.new File.read(path)
  end

  def self.set_layouts(merge_fields_list, template)
    layouts = []
    merge_fields_list.each do |merge_fields|
      template_array = YAML.load template.result binding
      template_array.each { |ar| layouts << ar }
    end
    layouts
  end

  def self.get_label_template_path(label_template_name)
    File.join('config', 'sprint', 'label_templates', label_template_name)
  end
end
