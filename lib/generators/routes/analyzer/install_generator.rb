require "rails/generators/base"

module Routes
  module Analyzer
    module Generators
      class InstallGenerator < Rails::Generators::Base
        desc "Install Routes Analyzer configuration file"

        def self.source_root
          @source_root ||= File.expand_path("templates", __dir__)
        end

        def create_configuration_file
          template "routes_analyzer.rb", "config/initializers/routes_analyzer.rb"
        end

        def show_instructions
          say "\n"
          say "Routes Analyzer has been installed!", :green
          say "\n"
          say "Configuration file created at: config/initializers/routes_analyzer.rb"
          say "\n"
          say "Next steps:"
          say "1. Configure your Redis connection in the initializer"
          say "2. Restart your Rails application"
          say "3. Use rake tasks to analyze your routes:"
          say "   - rails routes:analyzer:usage   # Show route usage statistics"
          say "   - rails routes:analyzer:config  # Check configuration"
          say "   - rails routes:analyzer:clear   # Clear usage data"
          say "\n"
        end
      end
    end
  end
end
