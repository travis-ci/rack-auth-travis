# vim:fileencoding=utf-8

require 'rack/lobster'

describe Rack::Auth::Travis do
  include Rack::Test::Methods

  def app
    Rack::Lobster.new
  end

  subject { described_class.new(app) }

  it 'inherits from Rack::Auth::AbstractHandler' do
    subject.class.superclass.should == Rack::Auth::AbstractHandler
  end

  it 'accepts config as a hash' do
    described_class.new(app, realm: 'foo').realm.should == 'foo'
  end

  it 'accepts an authenticator block' do
    handler = described_class.new(app) { |*| true }
    handler.instance_variable_get(:@authenticator).should_not be_nil
  end
end
