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
      client = status_cake do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      expect(client.uptime_checks).to eq response[:data]
    end

    it 'returns several pages of uptime checks' do
      response[:metadata][:page_count] = 3
      client = status_cake do |stub|
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

    it do
      client = status_cake do |stub|
        stub.post('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers.merge(form_request_headers)
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      expect(client.create_uptime(name: 'Example', website_url: 'example.com', check_rate: 30, test_type: 'HTTP')).to eq response
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
      client = status_cake do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, {'Content-Type': 'application/json'}, JSON.dump(response)]
        end
      end

      expect(client.uptime_test_id("AnotherTest")).to eq([230231111, 230231111])
    end
  end

end
