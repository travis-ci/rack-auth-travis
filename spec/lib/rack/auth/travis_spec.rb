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
end
