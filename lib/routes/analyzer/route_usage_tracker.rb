module Routes
  module Analyzer
    class RouteUsageTracker
      def initialize(configuration)
        @configuration = configuration
        @redis = configuration.redis_client
      end

      def get_usage_stats
        cutoff_time = @configuration.timeframe.days.ago.to_i

        # Get all route keys
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
            route: route_data["route"],
            method: route_data["method"],
            count: route_data["count"]&.to_i || 0,
            last_accessed: last_accessed ? Time.at(last_accessed) : nil
          }
        end

        # Sort by count (descending)
        usage_stats.sort_by { |stat| -stat[:count] }
      end

      def get_all_defined_routes
        return [] unless defined?(Rails) && Rails.application

        Rails.application.routes.routes.map do |route|
          {
            route: route.path.spec.to_s.gsub(/\(\.:format\)$/, ""),
            method: route.verb,
            controller: route.defaults[:controller],
            action: route.defaults[:action],
            name: route.name
          }
        end.compact.uniq { |r| [ r[:route], r[:method] ] }
      end

      def merge_with_defined_routes(usage_stats)
        defined_routes = get_all_defined_routes
        usage_by_route_method = usage_stats.index_by { |stat| "#{stat[:method]}:#{stat[:route]}" }

        merged_routes = []

        defined_routes.each do |defined_route|
          route_key = "#{defined_route[:method]}:#{defined_route[:route]}"
          usage_stat = usage_by_route_method[route_key]

          if usage_stat
            merged_routes << defined_route.merge(usage_stat)
          else
            merged_routes << defined_route.merge(
              count: 0,
              last_accessed: nil
            )
          end
        end

        # Add any tracked routes that aren't in the defined routes (in case of dynamic routes)
        usage_stats.each do |usage_stat|
          route_key = "#{usage_stat[:method]}:#{usage_stat[:route]}"
          unless defined_routes.any? { |dr| "#{dr[:method]}:#{dr[:route]}" == route_key }
            merged_routes << usage_stat.merge(
              controller: nil,
              action: nil,
              name: nil
            )
          end
        end

        # Sort by count (descending), then by route name
        merged_routes.sort_by { |route| [ -route[:count], route[:route] ] }
      end
    end
  end
end
