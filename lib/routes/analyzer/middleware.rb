require "redis"

module Routes
  module Analyzer
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, response = @app.call(env)

        # Track route usage after processing the request
        track_route_usage(env) if should_track?(env)

        [ status, headers, response ]
      end

      private

      def should_track?(env)
        # Only track if configuration is valid and we have a Rails route
        return false unless Routes::Analyzer.track_usage?
        return false unless env["action_controller.instance"]

        true
      rescue => e
        Rails.logger.warn "Routes::Analyzer: Failed to check tracking conditions: #{e.message}"
        false
      end

      def track_route_usage(env)
        request = Rack::Request.new(env)
        route_info = extract_route_info(env, request)

        return unless route_info

        redis_key = build_redis_key(route_info[:route], route_info[:method])
        current_time = Time.current

        configuration.redis_client.multi do |redis|
          # Increment counter
          redis.hincrby(redis_key, "count", 1)

          # Update last accessed timestamp
          redis.hset(redis_key, "last_accessed", current_time.to_i)

          # Set route and method info (in case it's the first time)
          redis.hset(redis_key, "route", route_info[:route])
          redis.hset(redis_key, "method", route_info[:method])

          # Set expiration based on timeframe (add some buffer)
          redis.expire(redis_key, (configuration.timeframe + 7) * 24 * 60 * 60)
        end

      rescue => e
        Rails.logger.warn "Routes::Analyzer: Failed to track route usage: #{e.message}"
      end

      def extract_route_info(env, request)
        # Get the matched route from Rails
        if env["action_controller.instance"]
          controller = env["action_controller.instance"]
          action = controller.action_name
          controller_name = controller.controller_name

          # Build route pattern from request path, removing query parameters
          route_path = request.path_info

          {
            route: route_path,
            method: request.request_method.upcase,
            controller: controller_name,
            action: action
          }
        end
      rescue => e
        Rails.logger.warn "Routes::Analyzer: Failed to extract route info: #{e.message}"
        nil
      end

      def build_redis_key(route, method)
        "#{configuration.redis_key_prefix}:#{method}:#{route.gsub('/', ':')}"
      end

      def configuration
        Routes::Analyzer.configuration
      end
    end
  end
end
