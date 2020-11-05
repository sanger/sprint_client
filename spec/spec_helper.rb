require 'bundler/setup'
Bundler.setup

require 'sprint_client'

RSpec.configure do |config|
  config.mock_framework = :rspec
end