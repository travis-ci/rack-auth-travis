# vim:fileencoding=utf-8

require 'rack/lint'
require 'rack-auth-travis'

ENV['TRAVIS_AUTH_DEFAULT'] = 'a' * 64

use Rack::Lint
use Rack::Auth::Travis, realm: 'justtesting'

echo = proc do |env|
  rack_input = env['rack.input'].read
  input_json = {
    'payload' => {
      'repository' => {
        'owner_name' => '',
        'name' => ''
      }
    }
  }
  error = nil

  begin
    input_json = JSON.parse(rack_input)
  rescue => e
    error = "#{e.class.name} #{e.message}"
  end

  body = <<-EOF.gsub(/^ {4}/, '')
    rack input length: #{rack_input.length}
      repo owner name: #{input_json['payload']['repository']['owner_name']}
            repo name: #{input_json['payload']['repository']['name']}
                error: #{error}
  EOF
  [
    200,
    {
      'Content-Length' => "#{body.length}",
      'Content-Type' => 'text/plain'
    },
    [body]
  ]
end

run echo
