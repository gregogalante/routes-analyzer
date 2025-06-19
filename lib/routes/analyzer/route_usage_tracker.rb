module Routes
  module Analyzer
    class RouteUsageTracker
      def initialize(configuration)
        @configuration = configuration
        @redis = configuration.redis_client
      end

      def get_usage_stats
        cutoff_time = @configuration.timeframe.days.ago.to_i

        # Get all controller#action keys
        pattern = "#{@configuration.redis_key_prefix}:*"
        keys = @redis.keys(pattern)

        usage_stats = []

        keys.each do |key|
          route_data = @redis.hgetall(key)
          next if route_data.empty?

          # Filter by timeframe if last_accessed is available
          last_accessed = route_data["last_accessed"]&.to_i
          next if last_accessed && last_accessed < cutoff_time

          usage_stats << {
            controller: route_data["controller"],
            action: route_data["action"],
            method: route_data["method"],
            count: route_data["count"]&.to_i || 0,
            last_accessed: last_accessed ? Time.at(last_accessed) : nil
          }
        end

        # Sort by count (descending)
        usage_stats.sort_by { |stat| -stat[:count] }
      end

      def get_all_defined_actions
        return [] unless defined?(Rails) && Rails.application

        actions = []
        Rails.application.routes.routes.each do |route|
          next unless route.defaults[:controller] && route.defaults[:action]

          actions << {
            controller: route.defaults[:controller],
            action: route.defaults[:action],
            method: route.verb,
            route: route.path.spec.to_s.gsub(/\(\.:format\)$/, ""),
            name: route.name
          }
        end

        # Remove duplicates based on controller#action (not method-specific)
        actions.uniq { |a| "#{a[:controller]}##{a[:action]}" }
      end

      def merge_with_defined_actions(usage_stats)
        defined_actions = get_all_defined_actions
        usage_by_action = usage_stats.index_by { |stat| "#{stat[:controller]}##{stat[:action]}" }

        merged_actions = []

        defined_actions.each do |defined_action|
          action_key = "#{defined_action[:controller]}##{defined_action[:action]}"
          usage_stat = usage_by_action[action_key]

          if usage_stat
            merged_actions << defined_action.merge(usage_stat)
          else
            merged_actions << defined_action.merge(
              count: 0,
              last_accessed: nil
            )
          end
        end

        # Add any tracked actions that aren't in the defined actions (in case of dynamic actions)
        usage_stats.each do |usage_stat|
          action_key = "#{usage_stat[:controller]}##{usage_stat[:action]}"
          unless defined_actions.any? { |da| "#{da[:controller]}##{da[:action]}" == action_key }
            merged_actions << usage_stat.merge(
              route: nil,
              name: nil
            )
          end
        end

        # Sort by count (descending), then by controller#action name
        merged_actions.sort_by { |action| [ -action[:count], "#{action[:controller]}##{action[:action]}" ] }
      end
    end
  end
end
