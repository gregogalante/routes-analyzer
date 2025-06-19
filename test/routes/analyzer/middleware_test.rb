require "test_helper"

class Routes::Analyzer::MiddlewareTest < ActiveSupport::TestCase
  def setup
    @app = ->(env) { [ 200, {}, [ "OK" ] ] }
    @middleware = Routes::Analyzer::Middleware.new(@app)
  end

  test "middleware passes through requests when not configured" do
    env = {}
    status, headers, response = @middleware.call(env)

    assert_equal 200, status
    assert_equal [ "OK" ], response
  end

  test "middleware does not crash when redis is not available" do
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://nonexistent:6379/0"
    end

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/test",
      "action_controller.instance" => mock_controller
    }

    assert_nothing_raised do
      @middleware.call(env)
    end
  end

  private

  def mock_controller
    MockController.new
  end

  class MockController
    def action_name
      "index"
    end

    def controller_name
      "test"
    end
  end
end
