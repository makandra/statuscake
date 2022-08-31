require 'byebug'
require 'active_support/core_ext/string'

class StatusCake::Client
  ENDPOINT = 'https://api.statuscake.com/v1'
  USER_AGENT = "Ruby StatusCake Client #{StatusCake::VERSION}"

  DEFAULT_ADAPTERS = [
    Faraday::Adapter::NetHttp,
    Faraday::Adapter::Test
  ]

  OPTIONS = [
    :API_KEY,
  ]

  def initialize(options)
    @options = {}
    @data = []

    OPTIONS.each do |key|
      @options[key] = options.delete(key)
    end

    options[:url] ||= ENDPOINT

    @conn = Faraday.new(options) do |faraday|
      faraday.request  :url_encoded
      faraday.response :json, :content_type => /\bjson$/
      faraday.response :raise_error
      faraday.response :logger, nil, { headers: true, bodies: true }

      yield(faraday) if block_given?

      unless DEFAULT_ADAPTERS.any? {|i| faraday.builder.handlers.include?(i) }
        faraday.adapter Faraday.default_adapter
      end
    end

    @conn.headers[:user_agent] = USER_AGENT
    # uptime_checks
  end

  def create_uptime(params = {})
    [:website_url, :test_type, :name, :check_rate].each do |param|
      if params[param].nil?
        raise ArgumentError, "#{param.to_s.humanize} has to be given as parameter."
      end
    end

    request("#{ENDPOINT}/uptime/", :post, params)
  end

  def test_id(name)

  end

  def retrieve_uptime_check(test_id, params = {})
    type_check test_id

    request("#{ENDPOINT}/uptime/#{test_id}", :get, params)
  end

  def update_uptime(test_id, params = {})
    type_check test_id
    if params.empty?
      raise ArgumentError, "No parameters were set to update."
    end

    request("#{ENDPOINT}/uptime/#{test_id}", :put, params)
  end

  def delete_uptime(test_id, params = {})
    type_check test_id

    request("#{ENDPOINT}/uptime/#{test_id}", :delete, params)
  end

  def uptime_check_history(test_id, params = {})
    type_check test_id

    request("#{ENDPOINT}/uptime/#{test_id}/history", :get, params)
  end

  def uptime_check_periods(test_id, params = {})
    type_check test_id

    request("#{ENDPOINT}/uptime/#{test_id}/periods", :get, params)
  end

  def uptime_check_alerts(test_id, params = {})
    type_check test_id

    request("#{ENDPOINT}/uptime/#{test_id}/alerts", :get, params)
  end

  def uptime_checks(params = {limit: 100})
    @data = []
    response = request("#{ENDPOINT}/uptime", :get, params)

    # cache the data so we don't have to talk to the API too often
    @data.concat response['data']

    page_count = response['metadata']['page_count']
    for page in 2..page_count do
      params['page'] = page
      page_response = request("#{ENDPOINT}/uptime", :get, params)
      @data.concat page_response['data']
    end

    @data
  end

  private

  def type_check(test_id)
    if test_id.class != String || test_id.class != Integer
      raise ArgumentError, "Test Id was of type #{test_id.class}, but has to be of type Integer or String."
    end
  end

  def request(path, method, params = {})
    response = @conn.send(method) do |req|
      req.url path

      case method
      when :get, :delete
        req.params = params
      when :post, :put
        req.body = params
      else
        raise 'must not happen'
      end

      req.headers[:Authorization] = "Bearer " + @options[:API_KEY]
      yield(req) if block_given?
    end

    json = response.body
    # XXX This validation does only the bare minimum currently
    validate_response(json)
    json
  end

  def validate_response(json)
    if json.kind_of?(Hash) and json.has_key?('errors')
      raise StatusCake::Error.new(json)
    end
  end
end
