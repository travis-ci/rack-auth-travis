require 'rack/auth/abstract/handler'

module Rack
  module Auth
    class Travis < ::Rack::Auth::AbstractHandler
      VERSION = '0.1.0'
    end
  end
end
