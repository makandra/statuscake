require 'statuscake'
require 'uri'
require 'byebug'

TEST_API_KEY = 'ReallySecretAPIToken'

def stub_client(options = {}, &block)
  options = {
    API_KEY: TEST_API_KEY
  }.merge(options)

  stubs = Faraday::Adapter::Test::Stubs.new
  described_class.new(options) do |faraday|
    faraday.adapter :test, stubs, &block
  end
end
