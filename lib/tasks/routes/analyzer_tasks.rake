namespace :routes do
  namespace :analyzer do
    desc "Show routes usage statistics"
    task usage: :environment do
      begin
        config = Routes::Analyzer.configuration
        tracker = Routes::Analyzer::RouteUsageTracker.new(config)

        puts "Routes Usage Analysis (#{config.timeframe} days)"
        puts "=" * 80
        puts

        if config.valid?
          usage_stats = tracker.get_usage_stats
          merged_routes = tracker.merge_with_defined_routes(usage_stats)
        else
          puts "Warning: Redis not configured. Showing defined routes only."
          puts
          merged_routes = tracker.get_all_defined_routes.map do |route|
            route.merge(count: 0, last_accessed: nil)
          end
        end

        if merged_routes.empty?
          puts "No routes found."
          next
        end

        # Print header
        printf "%-8s %-40s %-15s %-20s %s\n", "COUNT", "ROUTE", "METHOD", "CONTROLLER#ACTION", "LAST ACCESSED"
        puts "-" * 80

        merged_routes.each do |route|
          controller_action = if route[:controller] && route[:action]
            "#{route[:controller]}##{route[:action]}"
          else
            "N/A"
          end

          last_accessed = if route[:last_accessed]
            route[:last_accessed].strftime("%Y-%m-%d %H:%M")
          else
            "Never"
          end

          printf "%-8d %-40s %-15s %-20s %s\n",
                 route[:count],
                 route[:route].to_s[0, 40],
                 route[:method],
                 controller_action[0, 20],
                 last_accessed
        end

        puts
        puts "Total routes: #{merged_routes.count}"
        puts "Used routes: #{merged_routes.count { |r| r[:count] > 0 }}"
        puts "Unused routes: #{merged_routes.count { |r| r[:count] == 0 }}"

      rescue => e
        puts "Error: #{e.message}"
        puts "Make sure you have configured the routes analyzer properly."
        puts "Example configuration in config/initializers/routes_analyzer.rb:"
        puts
        puts "Routes::Analyzer.configure do |config|"
        puts "  config.redis_url = 'redis://localhost:6379/0'"
        puts "  config.redis_key_prefix = 'routes_analyzer'"
        puts "  config.timeframe = 30"
        puts "end"
      end
    end

    desc "Clear all routes usage data"
    task clear: :environment do
      begin
        config = Routes::Analyzer.configuration
        redis = config.redis_client
        pattern = "#{config.redis_key_prefix}:*"
        keys = redis.keys(pattern)

        if keys.any?
          redis.del(*keys)
          puts "Cleared #{keys.count} route usage records."
        else
          puts "No route usage data found to clear."
        end

      rescue => e
        puts "Error: #{e.message}"
      end
    end

    desc "Show configuration"
    task config: :environment do
      config = Routes::Analyzer.configuration
      puts "Routes Analyzer Configuration:"
      puts "- Redis URL: #{config.redis_url || 'Not configured'}"
      puts "- Redis Key Prefix: #{config.redis_key_prefix}"
      puts "- Timeframe: #{config.timeframe} days"

      begin
        if config.redis_client
          config.redis_client.ping
          puts "- Redis Connection: ✓ Connected"
        else
          puts "- Redis Connection: ✗ Not configured"
        end
      rescue => e
        puts "- Redis Connection: ✗ Failed (#{e.message})"
      end
    end
  end
end
