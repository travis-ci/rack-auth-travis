# vim:fileencoding=utf-8

require 'base64'
require 'json'
require 'rack/lobster'

describe Rack::Auth::Travis do
  include Rack::Test::Methods

  let :unprotected_app do
    Rack::Lobster.new
  end

  subject :protected_app do
    described_class.new(unprotected_app)
  end

  let :owner do
    "octocat#{rand(10..19)}"
  end

  let :repo do
    "deathrace#{rand(2000..2999)}"
  end

  let :repo_slug do
    [owner, repo].join('/')
  end

  let :token do
    Base64.encode64("#{rand(100..999)}#{rand(10e4..10e5)}")[0, 20]
  end

  let :valid_auth_header do
    described_class.authz(owner, repo, token)
  end

  let :valid_payload do
    Support.valid_payload(owner, repo)
  end

  let :valid_payload_json do
    JSON.pretty_generate(valid_payload)
  end

  it 'inherits from Rack::Auth::AbstractHandler' do
    expect(subject.class.superclass).to eq(Rack::Auth::AbstractHandler)
  end

  it 'accepts config as a hash' do
    expect(described_class.new(unprotected_app, realm: 'foo').realm)
      .to eq('foo')
  end

  it 'provides an array of default authenticators' do
    expect(described_class.default_authenticators).to_not be_empty
  end

  it 'provides a `.valid?` method for checking arbitrary request envs' do
    expect(described_class.valid?('HTTP_JUST_KIDDING' => '1')).to eq(false)
  end

  context 'when initialized with an authenticator block' do
    it 'adds a DIYAuthenticator' do
      handler = described_class.new(unprotected_app) { |*| true }
      authenticators = handler.instance_variable_get(:@authenticators)
      expect(authenticators.map { |a| a.class.name })
        .to include('Rack::Auth::Travis::DIYAuthenticator')
    end

    context 'when the request is authenticated' do
      def app
        described_class.new(unprotected_app) { |*| true }
      end

      it 'responds 200' do
        post '/', valid_payload_json, 'HTTP_AUTHORIZATION' => valid_auth_header,
                                      'CONTENT_TYPE' => 'application/json'
        expect(last_response.status).to eq(200)
      end
    end
  end

  context 'when the payload is not valid JSON' do
    def app
      protected_app
    end

    it 'does not explode' do
      post '/', '{asd', 'HTTP_AUTHORIZATION' => 'a' * 64,
                        'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to be < 500
    end
  end

  context 'when initialized without config or block' do
    it 'adds an ENVAuthenticator' do
      handler = described_class.new(unprotected_app)
      authenticators = handler.instance_variable_get(:@authenticators)
      expect(authenticators.map { |a| a.class.name })
        .to eq(['Rack::Auth::Travis::ENVAuthenticator'])
    end
  end

  context 'when no Authorization is provided' do
    def app
      protected_app
    end

    it 'responds 401' do
      post '/foo', '{}'
      expect(last_response.status).to eq(401)
    end
  end

  context 'when invalid Authorization is provided' do
    def app
      protected_app
    end

    it 'responds 401' do
      post '/', valid_payload_json, 'HTTP_AUTHORIZATION' => 'a' * 64,
                                    'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(401)
    end
  end

  context 'when valid Authorization is provided' do
    def app
      protected_app
    end

    let(:env_key) { described_class.repo_env_key(repo_slug) }

    before { ENV[env_key] = token }
    after { ENV[env_key] = nil }

    it 'responds 200' do
      post '/', valid_payload_json, 'HTTP_AUTHORIZATION' => valid_auth_header,
                                    'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(200)
    end

    context 'when Travis-Repo-Slug is present' do
      it 'does not consume rack.input' do
        expect_any_instance_of(Rack::Auth::Travis::Request)
          .to_not receive(:repository)
        post '/', valid_payload_json, 'HTTP_AUTHORIZATION' => valid_auth_header,
                                      'CONTENT_TYPE' => 'application/json',
                                      'HTTP_TRAVIS_REPO_SLUG' => repo_slug
        expect(last_response.status).to eq(200)
      end
    end
  end
end
