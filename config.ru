require 'rack/lobster'
require 'rack-auth-travis'

ENV['TRAVIS_AUTH_DEFAULT'] = 'a' * 64

use Rack::Auth::Travis
run Rack::Lobster.new
