# Routes::Analyzer

[![Gem Version](https://badge.fury.io/rb/routes-analyzer.svg)](https://badge.fury.io/rb/routes-analyzer)

A Ruby on Rails plugin that tracks and analyzes route usage in your application. It uses Redis to store route access patterns and provides insights into which routes are being used and which are not.

## Features

- **Route Usage Tracking**: Automatically tracks which routes are accessed and how often
- **Redis Storage**: Uses Redis to store usage statistics efficiently  
- **Configurable Timeframe**: Set custom analysis periods (default 30 days)
- **Comprehensive Reporting**: Shows both used and unused routes
- **Rake Tasks**: Easy-to-use commands for viewing statistics and managing data

## Installation

Add this line to your application's Gemfile:

```ruby
gem "routes-analyzer"
```

And then execute:
```bash
$ bundle install
```

## Configuration

After installation, generate the configuration file:

```bash
bundle exec rails generate routes:analyzer:install
```

This will create `config/initializers/routes_analyzer.rb` with the following content:

```ruby
Routes::Analyzer.configure do |config|
  # Redis connection URL
  config.redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
  
  # Redis key prefix for storing route usage data
  config.redis_key_prefix = 'routes_analyzer'
  
  # Timeframe for route usage analysis in days
  config.timeframe = 30
end
```

Alternatively, you can create the configuration file manually in `config/initializers/routes_analyzer.rb`.

### Configuration Options

- **redis_url**: The Redis connection URL (required)
- **redis_key_prefix**: Prefix for Redis keys to avoid conflicts (default: "routes_analyzer")
- **timeframe**: Number of days to consider for "recent" usage (default: 30)

## Usage

Once installed and configured, the middleware will automatically start tracking route usage. No additional code changes are required.

### Rake Tasks

#### View Route Usage Statistics

```bash
bundle exec rake routes:analyzer:usage
```

This command shows:
- All routes defined in your `routes.rb` file
- Usage count for each route in the specified timeframe
- Last access timestamp
- Summary statistics (total, used, unused routes)

Example output:
```
Routes Usage Analysis (30 days)
================================================================================

COUNT    ROUTE                                    METHOD          CONTROLLER#ACTION    LAST ACCESSED
--------------------------------------------------------------------------------
45       /users                                   GET             users#index          2025-06-18 14:30
23       /users/:id                              GET             users#show           2025-06-18 12:15
12       /posts                                   GET             posts#index          2025-06-17 09:45
0        /admin/reports                           GET             admin/reports#index  Never
0        /api/v1/health                          GET             api/v1/health#check  Never

Total routes: 5
Used routes: 3
Unused routes: 2
```

#### Clear Usage Data

```bash
bundle exec rake routes:analyzer:clear
```

Removes all stored route usage data from Redis.

#### Check Configuration

```bash
bundle exec rake routes:analyzer:config
```

Displays current configuration and tests Redis connectivity.

## How It Works

1. **Middleware Integration**: The plugin automatically adds middleware to your Rails application
2. **Request Tracking**: Each HTTP request is analyzed to extract route information
3. **Redis Storage**: Usage data is stored in Redis with the following structure:
   - Route path and HTTP method
   - Access count within the timeframe
   - Last access timestamp
4. **Data Expiration**: Redis keys automatically expire after the configured timeframe plus a buffer period

## Data Structure

For each tracked route, the following data is stored in Redis:

```ruby
{
  route: "/users/:id",           # Route pattern
  method: "GET",                 # HTTP method
  count: 15,                     # Number of accesses
  last_accessed: 1718721600      # Unix timestamp
}
```

## Requirements

- Ruby on Rails 8.0.2+
- Redis 5.0+

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a Pull Request

## Testing

Run the test suite to ensure everything is working correctly:

```bash
ruby bin/test
```

## Rubocop check

Run Rubocop to check code style:

```bash
ruby bin/rubocop
```

## Publishing

To publish a new version of the gem, update the version number in `lib/routes/analyzer/version.rb` and run:

```bash
ruby bin/publish
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
