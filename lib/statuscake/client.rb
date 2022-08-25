class StatusCake::Client
  ENDPOINT = 'https://api.statuscake.com/v1'
  USER_AGENT = "Ruby StatusCake Client 0.2.0"
  #USER_AGENT = "Ruby StatusCake Client #{StatusCake::VERSION}"

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

      yield(faraday) if block_given?

      unless DEFAULT_ADAPTERS.any? {|i| faraday.builder.handlers.include?(i) }
        faraday.adapter Faraday.default_adapter
      end
    end

    @conn.headers[:user_agent] = USER_AGENT
  end

  def uptime_create(identifier, params = {})
    method = params.delete(:method) || :post
    gather_uptime_tests
    # if identifier is an Integer, search for test_id
    # if identifier is a String search for name and get test_id

    request("#{ENDPOINT}/uptime/#{test_id}", method, params)
  end

  def uptime_delete(identifier, params = {})
    method = params.delete(:method) || :delete
    gather_uptime_tests
    # if identifier is an Integer, search for test_id
    # if identifier is a String search for name and get test_id

    request("#{ENDPOINT}/uptime/#{test_id}", method, params)
  end

  def uptime_update(identifier, params = {})
    method = params.delete(:method) || :put
    gather_uptime_tests
    # if identifier is an Integer, search for test_id
    # if identifier is a String search for name and get test_id

    request("#{ENDPOINT}/uptime/#{test_id}", method, params)
  end

  #private

  def gather_uptime_tests(params = {limit: 100})
    method = params.delete(:method) || :get
    data = []
    page_count = nil
    total_count = nil

    puts "GETTING PAGE 1"
    res = request("#{ENDPOINT}/uptime", method, params)
    data += res['data']

    page_count = res['metadata']['page_count']
    total_count = res['metadata']['total_count']

    # We're assuming there is no change in page count, while this runs
    for page in 2..page_count do
      puts "GETTING PAGE #{page} of #{page_count}"
      page_params = params
      page_params['page'] = page
      page_res = request("#{ENDPOINT}/uptime", method, page_params)
      data += page_res['data']
    end

    puts "Test if received amount of data is correct:"
    puts "We got this count of entries: #{data.size}"
    puts "StatusCake sees this count:   #{total_count}"
    # XXX Raise error if these numbers are not equal

    # cache the data so we don't have to talk to the API too often
    @data = data

    data
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
