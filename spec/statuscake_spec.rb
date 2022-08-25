describe StatusCake::Client do
  let(:request_headers) do
    {
      'User-Agent' => 'Ruby StatusCake Client 0.2.0',
      'Authorization' => "Bearer #{TEST_API_KEY}"
    }
  end

  let(:form_request_headers) do
    request_headers.merge(
      'Content-Type' => 'application/x-www-form-urlencoded'
    )
  end

  describe 'get /uptime' do
    let(:client) do
      stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, JSON.dump(response)]
        end
      end
    end

    let(:response) do
      {
        data: [
          {
            'id' => 230_230_230,
            'paused' => false,
            'name' => 'Test',
            'website_url' => 'https://www.test.com/',
            'test_type' => 'HTTP',
            'check_rate' => 300,
            'contact_groups' => ['21936'],
            'status' => 'up',
            'tags' => [],
            'uptime' => 100
          }
        ],
        metadata: {
          'page' => 1,
          'per_page' => 100,
          'page_count' => 1,
          'total_count' => 150
        }
      }
    end

    it 'returns one page of uptime checks' do
      expect(client.list_uptime_tests).to eq response[:data]
    end

    it 'returns several pages of uptime checks' do
      response[:metadata][:page_count] = 3

      uptime_checks = []
      3.times { uptime_checks.concat(response[:data]) }
      expect(client.list_uptime_tests).to eq uptime_checks
    end
  end

  describe 'post /uptime' do
    let(:response) do
      { 'data' => { 'new_id' => '6489923' } }
    end

    let(:client) do
      stub_client do |stub|
        stub.post('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers.merge(form_request_headers)
          [200, { 'Content-Type': 'application/json' }, JSON.dump(response)]
        end
      end
    end

    it 'creates a new uptime check' do
      expect(client.create_uptime_test(name: 'Example', website_url: 'example.com', check_rate: 30,
                                  test_type: 'HTTP')).to eq response
    end

    it 'raises an error when required parameters are not posted' do
      expect { client.create_uptime_test(website_url: 'example.com', check_rate: 30, test_type: 'HTTP')}.to raise_error(ArgumentError, 'name is a required parameter, but was not given.')
      expect { client.create_uptime_test(name: 'Example', check_rate: 30, test_type: 'HTTP') }.to raise_error(ArgumentError)
      expect { client.create_uptime_test(name: 'Example', website_url: 'example.com', test_type: 'HTTP') }.to raise_error(ArgumentError)
      expect {  client.create_uptime_test(name: 'Example', website_url: 'example.com', check_rate: 30) }.to raise_error(ArgumentError)
    end
  end

  describe '#get_uptime_test_id' do
    let(:response) do
      {
        data: [
          {
            'id' => 230_230_230,
            'name' => 'Test'
          },
          {
            'id' => 230_231_111,
            'name' => 'AnotherTest'
          },
          {
            'id' => 230_231_111,
            'name' => 'AnotherTest'
          }
        ],
        metadata: {
          'page' => 1,
          'page_count' => 1
        }
      }
    end

    it 'returns an array of ids for matching uptime checks' do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, JSON.dump(response)]
        end
      end

      expect(client.get_uptime_test_id('AnotherTest')).to eq [230_231_111, 230_231_111]
    end
  end

  describe 'get /uptime/test_id' do
    let(:response) do
      {
        'data' =>
         { 'id' => '6489923',
           'paused' => false,
           'name' => 'Example',
           'test_type' => 'HTTP',
           'website_url' => 'example.com',
           'check_rate' => 60,
           'confirmation' => 5,
           'contact_groups' => [],
           'do_not_find' => false,
           'enable_ssl_alert' => false,
           'follow_redirects' => false,
           'include_header' => false,
           'servers' => [],
           'processing' => false,
           'status' => 'up',
           'tags' => [],
           'timeout' => 40,
           'trigger_rate' => 4,
           'uptime' => 100,
           'use_jar' => false,
           'last_tested_at' => '2022-09-01T15:02:28+00:00',
           'next_location' => 'UNSET',
           'status_codes' => %w[500 501 502 503] }
      }
    end

    it do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime/6489923') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, JSON.dump(response)]
        end
      end

      expect(client.get_uptime_test(6_489_923)).to eq response
    end
  end

  describe 'put /uptime/test_id' do
    let(:client) do
      stub_client do |stub|
        stub.put('https://api.statuscake.com/v1/uptime/6489923') do |env|
          expect(env.request_headers).to eq request_headers.merge(form_request_headers)
          [200, { 'Content-Type': 'application/json' }, ' ']
        end
      end
    end

    it 'updates an uptime check' do
      expect(client.update_uptime_test(6_489_923, { name: 'example' })).to eq nil
    end

    it 'raises an error that no parameters were given' do
      expect { client.update_uptime_test(6_489_923, {}) }.to raise_error ArgumentError, 'No parameters were set to update.'
    end
  end

  describe 'get /uptime/test_id/history' do
    let(:response) do
      {
        'data' =>
          [
            {
              'created_at' => '2022-09-05T06:07:02+00:00',
              'status_code' => 200,
              'location' => 'XAK',
              'performance' => 27
            }, {
              'created_at' => '2022-09-05T06:05:55+00:00',
              'status_code' => 200,
              'location' => 'YBP',
              'performance' => 340
            }, {
              'created_at' => '2022-09-05T06:03:59+00:00',
              'status_code' => 200,
              'location' => 'SKW',
              'performance' => 194
            }
          ],
        'links' =>
          {
            'self' => 'https://api.statuscake.com/v1/uptime/6489923/history?limit=25&before=1662358051',
            'next' => 'https://api.statuscake.com/v1/uptime/6489923/history?limit=25&before=1662356356'
          }
      }
    end

    it do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime/6489923/history') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, response]
        end
      end

      expect(client.list_uptime_test_history(6_489_923)).to eq(response)
    end
  end

  describe 'get /uptime/test_id/periods' do
    let(:response) do
      {
        'data' =>
          [
            {
              'status' => 'up',
              'created_at' => '2022-09-01T14:25:46+00:00'
            }
          ], 'links' =>
          {
            'self' => 'https://api.statuscake.com/v1/uptime/6489923/periods?limit=25&before=1662359177',
            'next' => 'https://api.statuscake.com/v1/uptime/6489923/periods?limit=25&before=1662042346'
          }
      }
    end

    it do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime/6489923/periods') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, response]
        end
      end

      expect(client.list_uptime_test_periods(6_489_923)).to eq(response)
    end
  end

  describe 'get /uptime/test_id/alerts' do
    let(:response) do
      {
        'data' =>
          [
            {
              'id' => '6203700',
              'status' => 'up',
              'status_code' => 100,
              'triggered_at' => '2022-01-30T23:28:09+00:00'
            },
            {
              'id' => '6203700',
              'status' => 'down',
              'status_code' => 0,
              'triggered_at' => '2022-01-30T23:26:59+00:00'
            }
          ],
        'links' =>
          {
            'self' => 'https://api.statuscake.com/v1/uptime/6489923/alerts?limit=25&before=1662359526',
            'next' => 'https://api.statuscake.com/v1/uptime/6489923/alerts?limit=25&before=1643585219'
          }
      }
    end

    it do
      client = stub_client do |stub|
        stub.get('https://api.statuscake.com/v1/uptime/6489923/alerts') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, response]
        end
      end

      expect(client.list_uptime_test_alerts(6_489_923)).to eq(response)
    end
  end

  describe 'delete /uptime/test_id' do
    it do
      client = stub_client do |stub|
        stub.delete('https://api.statuscake.com/v1/uptime/6489923') do |env|
          expect(env.request_headers).to eq request_headers
          [200, { 'Content-Type': 'application/json' }, '']
        end
      end

      expect(client.delete_uptime_test(6_489_923)).to eq nil
    end
  end
end
