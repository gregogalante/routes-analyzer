module Routes
  module Analyzer
    class Configuration
      attr_accessor :redis_url, :redis_key_prefix, :timeframe

      def initialize
        @redis_url = nil
        @redis_key_prefix = "routes_analyzer"
        @timeframe = 30 # days
      end

      def redis_client
        @redis_client ||= Redis.new(url: redis_url) if redis_url
      end

      def validate!
        raise "Redis URL must be configured" unless redis_url

        # Test Redis connection
        redis_client.ping
      rescue Redis::BaseError => e
        raise "Failed to connect to Redis: #{e.message}"
      end

      def valid?
        return false unless redis_url

        redis_client.ping
        true
      rescue Redis::BaseError
        false
      end
    end
  end
end
