# SPrint Client Gem

## To build this gem
1. Update the **version number** in the gemspec
2. Run `gem build sprint_client.gemspec`
3. Run `gem push sprint_client-<version number>.gem`

## How to use this gem in an application
1. Add `gem 'sprint_client'` to the Gemfile.
2. Run `bundle install --full-index`
3. Add `SprintClient.sprint_uri = 'http://example.com'` to Rails initializer code, with the correct URI for SPrint
4. Call `SprintClient.send_print_request()` in the class where required

If you want to point to local gem
`gem 'sprint_client', path: "/Users/hc6/psd/sprint_client"`
`bundle update sprint_client`

If the above doesn't work
1. Run `gem list -r sprint_client` to check the gem is accessible
2. Run `gem install sprint_client`
1. Run `bundle install`

When updating
1. Run `bundle update sprint_client`

### Arguments for `send_print_request`:

| Argument | Description |
|----------|----------------|
| printer_name | a string showing which printer to send the request to |
| label_template_name | a string to identify which label template to be used in the print request |
| merge_fields_list | a list of hashes, each containing the field values for a particular label. For each hash in the merge_fields_list arguement, the keys match up to the label templates expected values |


### Full Example

`SprintClient.send_print_request("a printer", "a label template",[{ barcode: "DN111111", date: "1-APR-2020", barcode_text: "DN111111", workline_identifier: "DN111111", order_role: "Heron", plate_purpose: "LHR PCR 1" }, { barcode: "DN222222", date: "2-APR-2020" barcode_text: "DN222222", workline_identifier: "DN6222222", order_role: "Heron", plate_purpose: "LHR PCR 2" }])`

### Tests
Tests can be found in the spec/ folder

To run the unit tests run rspec. `bundle exec rspec`

We use rubocop to keep the code clean bundle exec rubocop