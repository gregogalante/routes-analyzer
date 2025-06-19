module Routes
  module Analyzer
    class Railtie < ::Rails::Railtie
      initializer "routes_analyzer.configure_middleware" do |app|
        app.middleware.use Routes::Analyzer::Middleware
      end

      rake_tasks do
        load "tasks/routes/analyzer_tasks.rake"
      end

      generators do
        require "generators/routes/analyzer/install_generator"
      end
    end
  end
end
