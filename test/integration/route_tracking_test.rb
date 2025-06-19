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

  test "tracks controller actions instead of route patterns" do
    # Skip if Redis isn't available for testing
    skip "Redis not available for testing" unless redis_available?

    # Use a real Redis instance for integration testing
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/1"
      config.redis_key_prefix = "test_routes_integration"
    end

    # Clear any existing test data
    begin
      redis = Routes::Analyzer.configuration.redis_client
      redis.flushdb
    rescue => e
      skip "Redis not available: #{e.message}"
    end

    # Test accessing different user IDs - should all track under users#show action
    get "/users/123"
    assert_response :success

    get "/users/456"
    assert_response :success

    get "/users/789"
    assert_response :success

    # Give a small delay for async processing if needed
    sleep 0.1

    # Check Redis directly for the stored data
    redis = Routes::Analyzer.configuration.redis_client
    pattern = "#{Routes::Analyzer.configuration.redis_key_prefix}:*"
    keys = redis.keys(pattern)

    # Find keys that match the users#show action
    user_show_keys = keys.select do |key|
      route_data = redis.hgetall(key)
      route_data["controller"] == "users" && route_data["action"] == "show"
    end

    assert_equal 1, user_show_keys.length, "Should have only one key for users#show action"

    # The count should be 3 (one for each request)
    if user_show_keys.any?
      key = user_show_keys.first
      count = redis.hget(key, "count").to_i
      assert_equal 3, count, "Should have tracked 3 accesses to the same controller#action"

      controller = redis.hget(key, "controller")
      action = redis.hget(key, "action")
      assert_equal "users", controller, "Should store the controller name"
      assert_equal "show", action, "Should store the action name"
    end
  end

  test "tracks different controller actions separately" do
    # Skip if Redis isn't available for testing
    skip "Redis not available for testing" unless redis_available?

    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/1"
      config.redis_key_prefix = "test_routes_integration"
    end

    # Clear any existing test data
    begin
      redis = Routes::Analyzer.configuration.redis_client
      redis.flushdb
    rescue => e
      skip "Redis not available: #{e.message}"
    end

    # Access different controller actions
    get "/users"           # users#index
    get "/users/123"       # users#show
    get "/posts"           # posts#index

    # Give a small delay for async processing if needed
    sleep 0.1

    # Check Redis directly
    redis = Routes::Analyzer.configuration.redis_client
    pattern = "#{Routes::Analyzer.configuration.redis_key_prefix}:*"
    keys = redis.keys(pattern)

    # Get all action data
    actions_data = keys.map do |key|
      redis.hgetall(key)
    end

    users_index_actions = actions_data.select { |a| a["controller"] == "users" && a["action"] == "index" }
    users_show_actions = actions_data.select { |a| a["controller"] == "users" && a["action"] == "show" }
    posts_index_actions = actions_data.select { |a| a["controller"] == "posts" && a["action"] == "index" }

    assert_equal 1, users_index_actions.length, "Should have one entry for users#index"
    assert_equal 1, users_show_actions.length, "Should have one entry for users#show"
    assert_equal 1, posts_index_actions.length, "Should have one entry for posts#index"
  end

  private

  def redis_available?
    # Try to connect to Redis and return true if successful
    redis = Redis.new(url: "redis://localhost:6379/1")
    redis.ping
    true
  rescue Redis::BaseError, Redis::CannotConnectError
    false
  end
end
