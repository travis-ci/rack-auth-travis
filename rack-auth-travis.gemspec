# vim:fileencoding=utf-8
Gem::Specification.new do |spec|
  spec.name = 'rack-auth-travis'
  spec.version = '0.2.0'
  spec.authors = ['Dan Buch']
  spec.email = ['dan@travis-ci.org']
  spec.summary = 'Rack auth for Travis CI webhook requests!'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/travis-ci/rack-auth-travis'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'rack'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'shotgun'
  spec.add_development_dependency 'simplecov'
end
