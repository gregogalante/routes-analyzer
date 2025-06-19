require "routes/analyzer/version"
require "routes/analyzer/railtie"
require "routes/analyzer/configuration"
require "routes/analyzer/middleware"
require "routes/analyzer/route_usage_tracker"

module Routes
  module Analyzer
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def track_usage?
        configuration.valid?
      rescue
        false
      end
    end
  end
end
