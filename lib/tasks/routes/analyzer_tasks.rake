namespace :routes do
  namespace :analyzer do
    desc "Show controller action usage statistics"
    task usage: :environment do
      begin
        config = Routes::Analyzer.configuration
        tracker = Routes::Analyzer::RouteUsageTracker.new(config)

        puts "Controller Action Usage Analysis (#{config.timeframe} days)"
        puts "=" * 80
        puts

        if config.valid?
          usage_stats = tracker.get_usage_stats
          merged_actions = tracker.merge_with_defined_actions(usage_stats)
        else
          puts "Warning: Redis not configured. Showing defined actions only."
          puts
          merged_actions = tracker.get_all_defined_actions.map do |action|
            action.merge(count: 0, last_accessed: nil)
          end
        end

        if merged_actions.empty?
          puts "No controller actions found."
          next
        end

        # Print header
        printf "%-8s %-40s %-15s %s\n", "COUNT", "CONTROLLER#ACTION", "METHOD", "LAST ACCESSED"
        puts "-" * 80

        merged_actions.each do |action|
          controller_action = if action[:controller] && action[:action]
            "#{action[:controller]}##{action[:action]}"
          else
            "N/A"
          end

          last_accessed = if action[:last_accessed]
            action[:last_accessed].strftime("%Y-%m-%d %H:%M")
          else
            "Never"
          end

          printf "%-8d %-40s %-15s %s\n",
                 action[:count],
                 controller_action[0, 40],
                 action[:method],
                 last_accessed
        end

        puts
        puts "Total actions: #{merged_actions.count}"
        puts "Used actions: #{merged_actions.count { |a| a[:count] > 0 }}"
        puts "Unused actions: #{merged_actions.count { |a| a[:count] == 0 }}"

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

    desc "Clear all controller action usage data"
    task clear: :environment do
      begin
        config = Routes::Analyzer.configuration
        redis = config.redis_client
        pattern = "#{config.redis_key_prefix}:*"
        keys = redis.keys(pattern)

        if keys.any?
          redis.del(*keys)
          puts "Cleared #{keys.count} controller action usage records."
        else
          puts "No controller action usage data found to clear."
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
