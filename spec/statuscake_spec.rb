describe StatusCake::Client do
  let(:request_headers) do
    {
      "User-Agent"    => "Ruby StatusCake Client 0.2.0",
      "Authorization" => "Bearer l6OxVJilcD2cETMoNRvn"
    }
  end

  let(:form_request_headers) do
    request_headers.merge(
      'Content-Type' => 'application/x-www-form-urlencoded'
    )
  end


  describe 'get /uptime' do
    let(:params) { {} }

    let(:response) do
      {
        data: [
          {
            "id"=>230230230,
              "paused"=>false,
              "name"=>"Test",
              "website_url"=>"https://www.test.com/",
              "test_type"=>"HTTP",
              "check_rate"=>300,
              "contact_groups"=>["21936"],
              "status"=>"up",
              "tags"=>[],
              "uptime"=>100
          }
        ],
        metadata: {
          "page"=>1,
          "per_page"=>100,
          "page_count"=>1,
          "total_count"=>150
        }
      }
    end

    it 'returns one page of uptime checks' do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      expect(client.uptime_checks).to eq response[:data]
    end

    it 'returns several pages of uptime checks' do
      response[:metadata][:page_count] = 3
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      uptime_checks = []
      3.times { uptime_checks.concat(response[:data]) }
      expect(client.uptime_checks).to eq uptime_checks
    end
  end


  describe 'post /uptime' do
    let(:response) do
      {"data"=>{"new_id"=>"6489923"}}
    end

    let(:client) do
      stub_client do |stub|
        stub.post('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers.merge(form_request_headers)
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end
    end

    it 'creates a new uptime check' do
      expect(client.create_uptime(name: 'Example', website_url: 'example.com', check_rate: 30, test_type: 'HTTP')).to eq response
    end

    it 'raises an error when required parameters are not posted' do
      expect { client.create_uptime(website_url: 'example.com', check_rate: 30, test_type: 'HTTP') }.to raise_error(ArgumentError, "Name is a required parameter, but was not given.")
      expect { client.create_uptime(name: 'Example', check_rate: 30, test_type: 'HTTP') }.to raise_error(ArgumentError)
      expect { client.create_uptime(name: 'Example', website_url: 'example.com', test_type: 'HTTP') }.to raise_error(ArgumentError)
      expect { client.create_uptime(name: 'Example', website_url: 'example.com', check_rate: 30) }.to raise_error(ArgumentError)
    end
  end

  describe '#uptime_test_id' do
    let(:response) do
      {
        data: [
          {
            "id"=>230230230,
            "name"=>"Test",
          },
          {
            "id"=>230231111,
            "name"=>"AnotherTest",
          },
          {
            "id"=>230231111,
            "name"=>"AnotherTest"
          }
        ],
        metadata: {
          "page"=>1,
          "page_count"=>1,
        }
      }
    end

    it 'returns an array of ids for matching uptime checks' do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      expect(client.uptime_test_id("AnotherTest")).to eq [230231111, 230231111]
    end
  end

  describe 'get /uptime/test_id' do
    let(:response) do
      {
        "data"=>
         {"id"=>"6489923",
          "paused"=>false,
          "name"=>"Example",
          "test_type"=>"HTTP",
          "website_url"=>"example.com",
          "check_rate"=>60,
          "confirmation"=>5,
          "contact_groups"=>[],
          "do_not_find"=>false,
          "enable_ssl_alert"=>false,
          "follow_redirects"=>false,
          "include_header"=>false,
          "servers"=>[],
          "processing"=>false,
          "status"=>"up",
          "tags"=>[],
          "timeout"=>40,
          "trigger_rate"=>4,
          "uptime"=>100,
          "use_jar"=>false,
          "last_tested_at"=>"2022-09-01T15:02:28+00:00",
          "next_location"=>"UNSET",
          "status_codes"=>[ "500", "501", "502", "503"]
         }
      }
    end

    it do
      client = stub_client do |stub|
        stub.get("https://api.statuscake.com/v1/uptime/6489923") do |env|
          expect(env.request_headers).to eq request_headers
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      expect(client.retrieve_uptime_check(6489923)).to eq response
    end
  end

  describe 'put /uptime/test_id' do
    it 'updates an uptime check' do
      client = stub_client do |stub|
        stub.put('https://api.statuscake.com/v1/uptime/6489923') do |env|
          expect(env.request_headers).to eq request_headers.merge(form_request_headers)
          [200, {'Content-Type': 'application/json'}, " "]
        end
      end

      expect(client.update_uptime(6489923, {name: "example"})).to eq nil
    end
  end

  it 'raises an error that no parameters were given' do
    client = stub_client do |stub|
      stub.put('https://api.statuscake.com/v1/uptime/6489923') do |env|
        expect(env.request_headers).to eq request_headers.merge(form_request_headers)
        [200, {'Content-Type': 'application/json'}, " "]
      end
    end

    expect { client.update_uptime(6489923, {}) }.to raise_error ArgumentError, "No parameters were set to update."
  end
end
