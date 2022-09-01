require 'byebug'

class StatusCake::Client
  ENDPOINT = 'https://api.statuscake.com/v1'
  USER_AGENT = "Ruby StatusCake Client #{StatusCake::VERSION}"

  OPTIONS = [
    :API_KEY,
  ]

  def initialize(options)
    @options = {}

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
    end

    @conn.headers[:user_agent] = USER_AGENT
  end

  def uptime_checks(params = {})
    params = {limit: 100}.merge(params)
    response = request("uptime", :get, params)
    uptime_checks = response['data']

    page_count = response['metadata']['page_count']
    for page in 2..page_count do
      params['page'] = page
      page_response = request("uptime", :get, params)
      uptime_checks.concat page_response['data']
    end

    uptime_checks
  end

  def create_uptime(params = {})
    [:website_url, :test_type, :name, :check_rate].each do |param|
      if params[param].nil?
        raise ArgumentError, "#{param.to_s.humanize} is a required parameter, but was not given."
      end
    end

    request("uptime", :post, params)
  end

  def uptime_test_id(name)
    checks_filtered_by_name = uptime_checks.select { |uptime_check| uptime_check['name'] == name }
    checks_filtered_by_name.map { |uptime_check| uptime_check['id'] }
  end

  def retrieve_uptime_check(test_id, params = {})
    type_check test_id

    request("uptime/#{test_id}", :get, params)
  end

  def update_uptime(test_id, params = {})
    type_check test_id
    if params.empty?
      raise ArgumentError, "No parameters were set to update."
    end

    request("uptime/#{test_id}", :put, params)
  end

  def delete_uptime(test_id, params = {})
    type_check test_id

    request("uptime/#{test_id}", :delete, params)
  end

  def uptime_check_history(test_id, params = {})
    type_check test_id

    request("uptime/#{test_id}/history", :get, params)
  end

  def uptime_check_periods(test_id, params = {})
    type_check test_id

    request("uptime/#{test_id}/periods", :get, params)
  end

  def uptime_check_alerts(test_id, params = {})
    type_check test_id

    request("uptime/#{test_id}/alerts", :get, params)
  end

  private

  def type_check(test_id)
    if test_id.class != String && test_id.class != Integer
      raise ArgumentError, "Test Id was of type #{test_id.class}, but has to be of type Integer or String."
    end
  end

  def request(path, method, params = {})
    path = "#{ENDPOINT}/#{path}"
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

    response.body
  end
end
