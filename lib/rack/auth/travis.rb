# vim:fileencoding=utf-8

require 'digest'
require 'json'
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

module Rack
  module Auth
    class Travis < ::Rack::Auth::AbstractHandler
      VERSION = '0.2.0'

      def self.authz(owner_name, name, token)
        ::Digest::SHA256.hexdigest([owner_name, name].join('/') + token)
      end

      def self.repo_env_key(repo_slug)
        "TRAVIS_AUTH_#{repo_slug.gsub(/[^\p{Alnum}]/, '_').upcase}"
      end

      def self.valid?(env)
        ::Rack::Auth::Travis::Request.new(env).valid?
      end

      def self.default_authenticators
        [
          ::Rack::Auth::Travis::ENVAuthenticator.new
        ]
      end

      def initialize(app, config = {}, &authenticator)
        @config = config
        @config[:sources] ||= [:env]
        super(app, config[:realm], &authenticator)
        configure_authenticators
      end

      def call(env)
        auth_req = Travis::Request.new(env, @authenticators)
        return unauthorized unless auth_req.provided?
        return bad_request unless auth_req.travis? && auth_req.json?
        return @app.call(env) if auth_req.valid?
        unauthorized
      end

      def build_env_authenticator
        ENVAuthenticator.new
      end

      def configure_authenticators
        @authenticators = []
        @config[:sources].each do |source|
          method_name = "build_#{source}_authenticator"
          @authenticators << send(method_name) if respond_to?(method_name)
        end
        if @authenticator
          @authenticators << DIYAuthenticator.new(@authenticator)
        end
      end

      def challenge
        %Q(Travis realm="#{realm}")
      end

      class DIYAuthenticator
        def initialize(authenticator_block)
          @authenticator_block = authenticator_block
        end

        def valid?(auth_req)
          @authenticator_block.call(auth_req.repo_slug, auth_req.token)
        end
      end

      class ENVAuthenticator
        def valid?(auth_req)
          [
            Travis.repo_env_key(auth_req.repo_slug),
            'TRAVIS_AUTH_DEFAULT'
          ].each do |k|
            env_auth_token = ENV[k]
            next unless env_auth_token
            return true if auth_req.token == authz(auth_req, env_auth_token)
          end
          false
        end

        def authz(auth_req, env_auth_token)
          Travis.authz(auth_req.owner_name, auth_req.name, env_auth_token)
        end
      end

      class Request < ::Rack::Auth::AbstractRequest
        JSON_REGEXP = /^application\/([\w!#\$%&\*`\-\.\^~]*\+)?json$/i

        def initialize(env, authenticators = Travis.default_authenticators)
          super(env)
          @authenticators = authenticators || []
        end

        def travis?
          token =~ /[\da-f]{64}/i
        end

        def json?
          request.env['CONTENT_TYPE'] =~ JSON_REGEXP
        end

        def valid?
          return false unless provided? && travis? && json?
          @authenticators.each do |authenticator|
            return true if authenticator.valid?(self)
          end
          false
        end

        def owner_name
          return @owner_name if @owner_name
          if x_travis_repo_slug
            @owner_name = x_travis_repo_slug.split('/').first
          else
            @owner_name = repository['owner_name']
          end
          @owner_name
        end

        def name
          return @name if @name
          if x_travis_repo_slug
            @name = x_travis_repo_slug.split('/').last
          else
            @name = repository['name']
          end
          @name
        end

        def repo_slug
          [owner_name, name].join('/')
        end

        def token
          @token ||= parts.first.to_s
        end

        def x_travis_repo_slug
          @x_travis_repo_slug ||= request.env['HTTP_X_TRAVIS_REPO_SLUG']
        end

        private

        def repository
          @repository ||= ((
            JSON.parse(request_body) || {}
          )['payload'] || {})['repository'] || {}
        rescue
          {}
        end

        def request_body
          @request_body ||= begin
                              body = request.env['rack.input'].read
                              request.env['rack.input'].rewind
                              body
                            end
        end
      end
    end
  end
end
