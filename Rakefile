# vim:fileencoding=utf-8

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '-f doc'
end

desc 'POST a valid payload'
task :payload do
  require 'rack-auth-travis'
  require 'net/http'
  require_relative 'spec/support'

  owner_name = ENV['OWNER_NAME'] || 'octocat'
  name = ENV['NAME'] || 'Knife-Spoon'
  ENV['TRAVIS_AUTH_DEFAULT'] ||= 'a' * 64
  token = ENV['TRAVIS_AUTH_DEFAULT']
  repo_env_key = Rack::Auth::Travis.repo_env_key("#{owner_name}/#{name}")
  ENV[repo_env_key] ||= token
  host = ENV['HOST'] || 'localhost'
  port = Integer(ENV['PORT'] || 9292)

  http = Net::HTTP.new(host, port)
  req = Net::HTTP::Post.new('/')
  req['Accept'] = 'application/json'
  req['Content-Type'] = 'application/json'
  req['Authorization'] = Rack::Auth::Travis.authz(owner_name, name, token)
  req.body = JSON.pretty_generate(Support.valid_payload(owner_name, name))

  $stdout.puts <<-EOF.gsub(/^ {4}/, '')
    OWNER_NAME=#{owner_name}
    NAME=#{name}
    TRAVIS_AUTH_DEFAULT=#{token}
    #{repo_env_key}=#{token}
    HOST=#{host}
    PORT=#{port}

    Authorization: #{req['Authorization']}

  EOF
  http.set_debug_output($stdout)
  reqbody = http.request(req).body
  File.open('rack-output.html', 'w') { |f| f.puts reqbody }
  $stdout.puts reqbody
end

desc 'Run rubocop'
task :rubocop do
  sh('rubocop --format simple') { |ok, _| ok || abort }
end

task default: [:rubocop, :spec]
