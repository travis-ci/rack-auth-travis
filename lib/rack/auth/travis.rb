# vim:fileencoding=utf-8

require 'digest'
require 'json'
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

module Rack
  module Auth
    class Travis < ::Rack::Auth::AbstractHandler
      VERSION = '0.1.0'

      def self.authz(owner_name, name, token)
        ::Digest::SHA256.hexdigest([owner_name, name].join('/') + token)
      end

      def self.repo_env_key(repo_slug)
        "TRAVIS_AUTH_#{repo_slug.gsub(/[^\p{Alnum}]/, '_').upcase}"
      end

      def initialize(app, config = {}, &authenticator)
        @config = config
        @config[:sources] ||= [:env]
        super(app, config[:realm], &authenticator)
        configure_authenticators
      end

      def call(env)
        auth_req = Travis::Request.new(env)
        return unauthorized unless auth_req.provided?
        return bad_request unless auth_req.travis? && auth_req.json?
        return @app.call(env) if valid?(auth_req)
        unauthorized
      end

      def build_env_authenticator
        ENVAuthenticator.new
      end

      private

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

      def valid?(auth_req)
        @authenticators.each do |authenticator|
          return true if authenticator.valid?(auth_req)
        end
        false
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
        def travis?
          token =~ /[\da-f]{64}/i
        end

        def json?
          request.env['CONTENT_TYPE'] =~ /^\s*application\/json/i
        end

        def owner_name
          @owner ||= repository['owner_name']
        end

        def name
          @name ||= repository['name']
        end

        def repo_slug
          [owner_name, name].join('/')
        end

        def token
          @token ||= parts.first.to_s
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
