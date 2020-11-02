# frozen_string_literal: true

# Interfaces with SPrint service: https://github.com/sanger/sprint
class SPrintClient
  require 'uri'
  require 'erb'
  require 'yaml'
  require 'net/http'
  require 'json'

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
    path = get_label_template_path(label_template_name)
    template = get_template(path)

    # parse the template for each label
    layouts = set_layouts(merge_fields_list, template)

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
  end

  def self.get_template(path)
    ERB.new File.read(path)
  end

  private
  
  def self.set_layouts(merge_fields_list, template)
    return merge_fields_list.map do |merge_fields|
      YAML.load template.result binding
    end
  end

  def self.get_label_template_path(label_template_name)
    File.join('config', 'sprint', 'label_templates', label_template_name)
  end

end
