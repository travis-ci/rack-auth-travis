# vim:fileencoding=utf-8

require 'rack/auth/abstract/handler'

module Rack
  module Auth
    class Travis < ::Rack::Auth::AbstractHandler
      VERSION = '0.1.0'

      def initialize(app, config = {}, &authenticator)
        @config = config
        super(app, config[:realm], &authenticator)
      end
    end
  end
end
