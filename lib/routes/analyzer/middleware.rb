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

        # Check if the route is actually defined in routes.rb
        return false unless route_defined_in_rails?(env)

        true
      rescue => e
        Rails.logger.warn "Routes::Analyzer: Failed to check tracking conditions: #{e.message}"
        false
      end

      def track_route_usage(env)
        request = Rack::Request.new(env)
        route_info = extract_route_info(env, request)

        return unless route_info

        redis_key = build_redis_key(route_info[:controller], route_info[:action])
        current_time = Time.current

        configuration.redis_client.multi do |redis|
          # Increment counter
          redis.hincrby(redis_key, "count", 1)

          # Update last accessed timestamp
          redis.hset(redis_key, "last_accessed", current_time.to_i)

          # Set controller#action and method info (in case it's the first time)
          redis.hset(redis_key, "controller", route_info[:controller])
          redis.hset(redis_key, "action", route_info[:action])
          redis.hset(redis_key, "method", route_info[:method])

          # Set expiration based on timeframe (add some buffer)
          redis.expire(redis_key, (configuration.timeframe + 7) * 24 * 60 * 60)
        end

      rescue => e
        Rails.logger.warn "Routes::Analyzer: Failed to track route usage: #{e.message}"
      end

      def route_defined_in_rails?(env)
        request = Rack::Request.new(env)

        # First check: if Rails didn't set path_parameters, it means the route wasn't recognized
        # This happens when Rails can't match the request to any defined route
        path_params = env["action_dispatch.request.path_parameters"]
        return false unless path_params

        # Second check: verify that Rails can recognize this path/method combination
        # This ensures the route is actually defined in routes.rb and not just handled by a catch-all
        route_exists = Rails.application.routes.recognize_path(
          request.path_info,
          method: request.request_method.downcase.to_sym
        )

        return true if route_exists
        false
      rescue ActionController::RoutingError, NoMethodError
        # If recognize_path raises RoutingError, the route is not defined in routes.rb
        # NoMethodError can occur if the controller/action doesn't exist
        false
      rescue => e
        Rails.logger.warn "Routes::Analyzer: Error checking route definition: #{e.message}"
        false
      end

      def extract_route_info(env, request)
        # Get the matched route from Rails
        if env["action_controller.instance"]
          controller = env["action_controller.instance"]
          action = controller.action_name
          controller_name = controller.controller_name
          method = request.request_method.upcase

          {
            controller: controller_name,
            action: action,
            method: method
          }
        end
      rescue => e
        Rails.logger.warn "Routes::Analyzer: Failed to extract route info: #{e.message}"
        nil
      end

      def build_redis_key(controller, action)
        "#{configuration.redis_key_prefix}:#{controller}##{action}"
      end

      def configuration
        Routes::Analyzer.configuration
      end
    end
  end
end
