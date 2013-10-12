# vim:fileencoding=utf-8

require 'erb'
require 'json'

module Echoplex
  HEADER = <<-EOF.gsub(/^ {4}/, '')
    <!DOCTYPE html>
    <html>
      <head>
        <title>rack-auth-travis example</title>
        <style type="text/css">body { font-family: Menlo, monospace; }</style>
      </head>
      <body>
        <h1>rack-auth-travis example</h1>
  EOF

  FOOTER = <<-EOF.gsub(/^ {4}/, '')
      </body>
    </html>
  EOF

  FORM = ERB.new(<<-EOF)
    <form action="protected" method="post">
      <div>
        <label for="owner_name">Repo Owner</label>
      </div>
      <div>
        <input type="text" id="owner_name" name="owner_name"
          placeholder="<github user/org>" value="<%= @owner_name %>"
          size="40" />
      </div>
      <div>
        <label for="name">Repo Name</label>
      </div>
      <div>
        <input type="text" id="name" name="name"
          placeholder="<github repo>" value="<%= @name %>"
          size="40" />
      </div>
      <div>
        <label for="token">Token</label>
      </div>
      <div>
        <input type="text" id="token" name="token"
          placeholder="<travis token>" value="<%= @token %>"
          size="30" maxlength="20" />
      </div>
      <div>
        <label for="payload">JSON payload</label>
      </div>
      <textarea id="payload" name="payload" rows="20" cols="80"></textarea>
      <div>
        <button id="fake_submit">POST</button>
      </div>
    </form>
    <script
      src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js">
    </script>
    <script src="/sha256.js"></script>
    <script type="text/javascript">
    $( function () {
      function travisAuthz ( ownerName, name, token ) {
        var toHash = ownerName + '/' + name + token;
        return CryptoJS.SHA256( toHash ).toString( CryptoJS.enc.Hex );
      }

      $( '#fake_submit' ).click( function ( event ) {
        event.preventDefault();
        var payload = $( '#payload' ).text();
        $.ajax({
          url: 'protected',
          type: 'POST',
          headers: {
            'Authorization': travisAuthz(
              $( '#owner_name' ).attr( 'value' ),
              $( '#name' ).attr( 'value' ),
              $( '#token' ).attr( 'value' )
            )
          },
          contentType: 'application/json',
          data: payload,
          dataType: 'html',
          success: function( data ) {
            $( 'body' ).html( data );
          }
        });
      });
    });
    </script>
  EOF

  POST_BODY = ERB.new(<<-EOF)
    <dl>
      <dt>rack input length</dt>
      <dd><%= @input_length.inspect %></dd>
      <dt>repo owner name</dt>
      <dd><%= @owner_name.inspect %></dd>
      <dt>repo name</dt>
      <dd><%= @name.inspect %></dd>
      <dt>error</dt>
      <dd><%= @error.inspect %></dd>
    </dl>
  EOF

  EMPTY_INPUT_JSON = {
    'payload' => {
      'repository' => {
        'owner_name' => '',
        'name' => ''
      }
    }
  }.freeze

  class App
    def call(env)
      request = Rack::Request.new(env)
      send("handle_#{request.request_method.downcase}", request)
    end

    private

    def handle_get(request)
      body = make_a_page { build_form(request) }
      [
        200,
        {
          'Content-Type' => 'text/html',
          'Content-Length' => "#{body.length}"
        },
        [body]
      ]
    end

    def build_form(request)
      @owner_name = ENV['TRAVIS_REPO_OWNER_NAME']
      @name = ENV['TRAVIS_REPO_NAME']
      @token = ENV['TRAVIS_AUTH_DEFAULT']
      Echoplex::FORM.result(binding)
    end

    def handle_post(request)
      rack_input, input_json, error = extract_post_data(request)
      body = make_a_page { post_body(rack_input.length, input_json, error) }
      [
        201,
        {
          'Content-Length' => "#{body.length}",
          'Content-Type' => 'text/html'
        },
        [body]
      ]
    end

    def extract_post_data(request)
      rack_input = request.env['rack.input'].read
      input_json = Echoplex::EMPTY_INPUT_JSON.clone
      error = nil

      begin
        input_json = JSON.parse(rack_input)
      rescue => e
        error = "#{e.class.name} #{e.message}"
      end

      [rack_input, input_json, error]
    end

    def post_body(input_length, input_json, error)
      @input_length = input_length
      @owner_name = input_json['payload']['repository']['owner_name']
      @name = input_json['payload']['repository']['name']
      @error = error
      Echoplex::POST_BODY.result(binding)
    end

    def make_a_page
      [Echoplex::HEADER, yield, Echoplex::FOOTER].join("\n")
    end
  end
end
