# frozen_string_literal: true

# Interfaces with SPrint service: https://github.com/sanger/sprint 
class SprintClient
  require 'uri'
  require 'erb'
        
  # printer_name - a string showing which printer to send the request to
  # label_template_name - a string to identify which label template to be used in the print request
  # merge_fields_list - a list of hashes, each containing the field values for a particular label
  #   e.g [{ barcode: "DN111111", date: "1-APR-2020" }, { barcode: "DN222222", date: "2-APR-2020" }] would print two labels
  def self.send_print_request(printer_name, label_template_name, merge_fields_list)
    # define GraphQL print mutation
    query = "mutation Print($printRequest: PrintRequest!, $printer: String!) {
      print(printRequest: $printRequest, printer: $printer) {
        jobId
      }
    }"

    # locate the required label template    
    path = File.join('config', 'sprint', 'label_templates', label_template_name)
    template = ERB.new File.read(path)

    # parse the template for each label
    layouts = merge_fields_list.map do |merge_fields|
      YAML.load template.result binding
    end

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

    # send POST request to SPrint url and return response
    Net::HTTP.post URI(configatron.sprint_url),
                              body.to_json,
                              'Content-Type' => 'application/json'

  end
end
