# vim:fileencoding=utf-8

require 'open-uri'
require 'rack/lint'
require 'rack/urlmap'
require 'rack-auth-travis'
require './echoplex'

ENV['TRAVIS_AUTH_DEFAULT'] ||= 'a' * 20
ENV['TRAVIS_REPO_OWNER_NAME'] ||= 'foo'
ENV['TRAVIS_REPO_NAME'] ||= 'bar'

sha256js = File.expand_path('../public/sha256.js', __FILE__)

if !File.exist?(sha256js)
  File.open(sha256js, 'w') do |f|
    open(
      'http://crypto-js.googlecode.com/svn/tags/3.1.2/build/rollups/sha256.js'
    ) do |uri_f|
      uri_f.each_line { |l| f.write l }
    end
  end
end

app = Echoplex::App.new
protected_app = Rack::Auth::Travis.new(app, realm: 'echoplex')

run Rack::URLMap.new(
  '/unprotected' => Rack::Lint.new(app),
  '/protected' => Rack::Lint.new(protected_app),
  '/' => Rack::Directory.new(File.expand_path('../public', __FILE__))
)
