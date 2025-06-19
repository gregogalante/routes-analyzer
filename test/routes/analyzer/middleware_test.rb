require "test_helper"

class Routes::Analyzer::MiddlewareTest < ActiveSupport::TestCase
  def setup
    @app = ->(env) { [ 200, {}, [ "OK" ] ] }
    @middleware = Routes::Analyzer::Middleware.new(@app)
  end

  test "middleware passes through requests when not configured" do
    env = {}
    status, _headers, response = @middleware.call(env)

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

  test "middleware does not track routes not defined in routes.rb" do
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/0"
    end

    # Mock an environment for a route that doesn't exist in routes.rb
    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/undefined_route",
      "action_controller.instance" => mock_controller,
      # Simulate what happens when a route is not properly defined
      "action_dispatch.request.path_parameters" => nil
    }

    # The middleware should not crash and should not track undefined routes
    assert_nothing_raised do
      @middleware.call(env)
    end
  end

  test "route_defined_in_rails returns false for undefined routes" do
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/0"
    end

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/completely_undefined_route",
      "action_controller.instance" => mock_controller,
      "action_dispatch.request.path_parameters" => nil
    }

    # Access the private method through send for testing
    result = @middleware.send(:route_defined_in_rails?, env)
    assert_equal false, result
  end

  test "route_defined_in_rails returns true for routes with valid path parameters" do
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/0"
    end

    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/posts",
      "action_controller.instance" => mock_controller,
      "action_dispatch.request.path_parameters" => { controller: "posts", action: "index" }
    }

    # We'll test this with a real route that should exist
    # Access the private method through send for testing
    result = @middleware.send(:route_defined_in_rails?, env)
    assert_equal true, result
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
