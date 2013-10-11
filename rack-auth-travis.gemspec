# vim:fileencoding=utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/auth/travis'

Gem::Specification.new do |spec|
  spec.name          = 'rack-auth-travis'
  spec.version       = Rack::Auth::Travis::VERSION
  spec.authors       = ['Dan Buch']
  spec.email         = ['d.buch@modcloth.com']
  spec.summary       = %q{Rack auth for Travis CI webhook requests!}
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/modcloth-labs/rack-auth-travis'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rack'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
