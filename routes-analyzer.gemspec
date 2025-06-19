require_relative "lib/routes/analyzer/version"

Gem::Specification.new do |spec|
  spec.name        = "routes-analyzer"
  spec.version     = Routes::Analyzer::VERSION
  spec.authors     = [ "Gregorio Galante" ]
  spec.email       = [ "me@gregoriogalante.com" ]
  spec.homepage    = "https://github.com/gregogalante/routes-analyzer"
  spec.summary     = "Track and analyze Ruby on Rails route usage with Redis"
  spec.description = "A Rails plugin that automatically tracks route usage patterns and provides insights into which routes are being used and which are not. Uses Redis for efficient storage and includes rake tasks for analysis."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.2"
  spec.add_dependency "redis", ">= 5.0"
end
