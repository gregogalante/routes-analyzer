require "test_helper"

class Routes::Analyzer::RouteUsageTrackerTest < ActiveSupport::TestCase
  def setup
    @config = Routes::Analyzer::Configuration.new
    @config.redis_key_prefix = "test_routes"
    @config.timeframe = 30

    @tracker = Routes::Analyzer::RouteUsageTracker.new(@config)
  end

  test "get_all_defined_routes returns empty array when Rails is not available" do
    # Save current Rails constant
    rails_backup = nil
    if defined?(Rails)
      rails_backup = Rails
      Object.send(:remove_const, :Rails)
    end

    routes = @tracker.get_all_defined_routes
    assert_equal [], routes

    # Restore Rails constant
    Object.const_set(:Rails, rails_backup) if rails_backup
  end

  test "merge_with_defined_routes combines usage stats with defined routes" do
    # Mock defined routes method
    def @tracker.get_all_defined_routes
      [
        {
          route: "/users",
          method: "GET",
          controller: "users",
          action: "index",
          name: "users"
        },
        {
          route: "/posts",
          method: "GET",
          controller: "posts",
          action: "index",
          name: "posts"
        }
      ]
    end

    usage_stats = [
      { route: "/users", method: "GET", count: 10, last_accessed: Time.current }
    ]

    merged = @tracker.merge_with_defined_routes(usage_stats)

    assert_equal 2, merged.length

    # Used route
    used_route = merged.find { |r| r[:route] == "/users" && r[:method] == "GET" }
    assert_equal 10, used_route[:count]

    # Unused route
    unused_route = merged.find { |r| r[:route] == "/posts" && r[:method] == "GET" }
    assert_equal 0, unused_route[:count]
    assert_nil unused_route[:last_accessed]
  end
end
