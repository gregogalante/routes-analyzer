require "test_helper"

class Routes::Analyzer::RouteUsageTrackerTest < ActiveSupport::TestCase
  def setup
    @config = Routes::Analyzer::Configuration.new
    @config.redis_key_prefix = "test_routes"
    @config.timeframe = 30

    @tracker = Routes::Analyzer::RouteUsageTracker.new(@config)
  end

  test "get_all_defined_actions returns empty array when Rails is not available" do
    # Save current Rails constant
    rails_backup = nil
    if defined?(Rails)
      rails_backup = Rails
      Object.send(:remove_const, :Rails)
    end

    actions = @tracker.get_all_defined_actions
    assert_equal [], actions

    # Restore Rails constant
    Object.const_set(:Rails, rails_backup) if rails_backup
  end

  test "merge_with_defined_actions combines usage stats with defined actions" do
    # Mock defined actions method
    def @tracker.get_all_defined_actions
      [
        {
          controller: "users",
          action: "index",
          method: "GET",
          route: "/users",
          name: "users"
        },
        {
          controller: "posts",
          action: "index",
          method: "GET",
          route: "/posts",
          name: "posts"
        }
      ]
    end

    usage_stats = [
      { controller: "users", action: "index", method: "GET", count: 10, last_accessed: Time.current }
    ]

    merged = @tracker.merge_with_defined_actions(usage_stats)

    assert_equal 2, merged.length

    # Used action
    used_action = merged.find { |a| a[:controller] == "users" && a[:action] == "index" }
    assert_equal 10, used_action[:count]

    # Unused action
    unused_action = merged.find { |a| a[:controller] == "posts" && a[:action] == "index" }
    assert_equal 0, unused_action[:count]
    assert_nil unused_action[:last_accessed]
  end
end
