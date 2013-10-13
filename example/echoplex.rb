# vim:fileencoding=utf-8

require 'json'
require 'sinatra/base'

module Echoplex
  class App < Sinatra::Base
    set :public_dir, File.expand_path('../public', __FILE__)

    get '/' do
      @owner_name = ENV['TRAVIS_REPO_OWNER_NAME']
      @name = ENV['TRAVIS_REPO_NAME']
      @token = ENV['TRAVIS_AUTH_DEFAULT']
      @default_json = JSON.pretty_generate(
        payload: { repository: { owner_name: @owner_name, name: @name } }
      )
      erb :index
    end

    post '/' do
      rack_input, input_json, error = extract_post_data(request)
      @authz = request.env['HTTP_AUTHORIZATION']
      @input_length = rack_input.length
      @owner_name = (
        (input_json['payload'] || {})['repository'] || {}
      )['owner_name']
      @name = (
        (input_json['payload'] || {})['repository'] || {}
      )['name']
      @error = error
      @env = request.env
      erb :result, layout: !request.xhr?
    end

    private

    def extract_post_data(request)
      rack_input = request.env['rack.input'].read
      input_json = {}
      error = nil

      begin
        input_json = JSON.parse(rack_input)
      rescue => e
        error = "#{e.class.name} #{e.message}"
      end

      [rack_input, input_json, error]
    end
  end
end
