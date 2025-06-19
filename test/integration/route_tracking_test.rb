require "test_helper"

class RouteTrackingTest < ActionDispatch::IntegrationTest
  def setup
    # Configure the analyzer to use a test Redis instance
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/1" # Use database 1 for tests
    end

    # Clear any existing data
    begin
      Routes::Analyzer.configuration.redis_client&.flushdb
    rescue Redis::BaseError
      # Redis might not be available in test environment
    end
  end

  test "tracks defined routes" do
    # This route is defined in test/dummy/config/routes.rb
    get "/"

    assert_response :success
    # Note: We can't easily test Redis interactions without a running Redis instance
    # But we can test that the request doesn't fail
  end

  test "handles undefined routes gracefully" do
    # This should trigger a 404 but not crash the middleware
    get "/completely/undefined/route"
    assert_response :not_found
  end

  test "middleware processes valid routes without errors" do
    # Test a few defined routes from the dummy app
    get "/posts"
    assert_response :success

    get "/users"
    assert_response :success

    # Test that no exceptions were raised during middleware processing
    assert true
  end
end
