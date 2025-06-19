require "test_helper"

class Routes::AnalyzerTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Routes::Analyzer::VERSION
  end

  test "configuration can be set" do
    Routes::Analyzer.configure do |config|
      config.redis_url = "redis://localhost:6379/1"
      config.redis_key_prefix = "test_routes"
      config.timeframe = 7
    end

    config = Routes::Analyzer.configuration
    assert_equal "redis://localhost:6379/1", config.redis_url
    assert_equal "test_routes", config.redis_key_prefix
    assert_equal 7, config.timeframe
  end

  test "configuration has default values" do
    config = Routes::Analyzer::Configuration.new
    assert_equal "routes_analyzer", config.redis_key_prefix
    assert_equal 30, config.timeframe
    assert_nil config.redis_url
  end
end
