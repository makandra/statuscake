require 'statuscake'
require 'uri'
require 'byebug'

TEST_API_KEY  = 'l6OxVJilcD2cETMoNRvn'

def stub_client(options = {})
  options = {
    API_KEY: TEST_API_KEY,
  }.merge(options)

  stubs = Faraday::Adapter::Test::Stubs.new
  described_class.new(options) do |faraday|
    faraday.adapter :test, stubs do |stub|
      yield(stub)
    end
  end
end

def stringify_hash(hash)
  Hash[*hash.map {|k, v| [k.to_s, v.to_s] }.flatten(1)]
end
