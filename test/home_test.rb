$LOAD_PATH << '.'
require 'rack/test'
require 'test/unit'
require 'home'

ENV['RACK_ENV'] = 'test'

class HelloTest < Test::Unit::TestCase
  include::Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_it_renders_home_page
    get '/'
    assert last_response.ok?
  end
end
