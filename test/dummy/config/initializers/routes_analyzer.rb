# Configuration for Routes Analyzer
# This plugin tracks route usage in your Rails application using Redis

Routes::Analyzer.configure do |config|
  # Redis connection URL
  # You can use environment variables to keep this secure
  # Examples:
  #   - redis://localhost:6379/0
  #   - redis://username:password@localhost:6379/0
  #   - rediss://localhost:6380/0 (for SSL/TLS)
  config.redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
  
  # Redis key prefix for storing route usage data
  # This helps avoid conflicts with other Redis data in your application
  config.redis_key_prefix = 'routes_analyzer'
  
  # Timeframe for route usage analysis in days
  # Only routes accessed within this timeframe will be considered "active"
  # This also determines how long data is stored in Redis
  config.timeframe = 30
end
