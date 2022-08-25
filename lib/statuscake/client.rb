class StatusCake::Client
  ENDPOINT = 'https://api.statuscake.com/v1'
  USER_AGENT = "Ruby StatusCake Client #{StatusCake::VERSION}"

  OPTIONS = [
    :API_KEY
  ]

  def initialize(options)
    @options = {}

    OPTIONS.each do |key|
      @options[key] = options.delete(key)
    end

    options[:url] ||= ENDPOINT

    @conn = Faraday.new(options) do |faraday|
      faraday.request  :url_encoded
      faraday.response :json, content_type: /\bjson$/
      faraday.response :raise_error

      yield(faraday) if block_given?
    end

    @conn.headers[:user_agent] = USER_AGENT
  end

  def list_uptime_tests(params = {})
    params = { limit: 100 }.merge(params)
    response = request('uptime', :get, params)
    uptime_checks = response['data']

    page_count = response['metadata']['page_count']
    (2..page_count).each do |page|
      params['page'] = page
      page_response = request('uptime', :get, params)
      uptime_checks.concat(page_response['data'])
    end

    uptime_checks
  end

  def create_uptime_test(params)
    %i[website_url test_type name check_rate].each do |param|
      raise ArgumentError, "#{param} is a required parameter, but was not given." if params[param].nil?
    end

    request('uptime', :post, params)
  end

  def get_uptime_test_id(name)
    checks_filtered_by_name = list_uptime_tests.select { |uptime_check| uptime_check['name'] == name }
    checks_filtered_by_name.map { |uptime_check| uptime_check['id'] }
  end

  def get_uptime_test(test_id, params = {})
    request("uptime/#{test_id}", :get, params)
  end

  def update_uptime_test(test_id, params)
    raise ArgumentError, 'No parameters were set to update.' if params.empty?

    request("uptime/#{test_id}", :put, params)
  end

  def delete_uptime_test(test_id, params = {})
    request("uptime/#{test_id}", :delete, params)
  end

  def list_uptime_test_history(test_id, params = {})
    request("uptime/#{test_id}/history", :get, params)
  end

  def list_uptime_test_periods(test_id, params = {})
    request("uptime/#{test_id}/periods", :get, params)
  end

  def list_uptime_test_alerts(test_id, params = {})
    request("uptime/#{test_id}/alerts", :get, params)
  end

  private

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

      req.headers[:Authorization] = "Bearer #{@options[:API_KEY]}"
      yield(req) if block_given?
    end

    response.body
  end
end
