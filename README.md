# Routes::Analyzer

[![Gem Version](https://badge.fury.io/rb/routes-analyzer.svg)](https://badge.fury.io/rb/routes-analyzer)

A Ruby on Rails plugin that tracks and analyzes controller action usage in your application. It uses Redis to store action access patterns and provides insights into which controller actions are being used and which are not.

## Features

- **Controller Action Tracking**: Automatically tracks which controller actions are accessed and how often
- **Method-Agnostic Tracking**: Actions are tracked by controller#action regardless of HTTP method (GET, POST, etc.)
- **Redis Storage**: Uses Redis to store usage statistics efficiently  
- **Configurable Timeframe**: Set custom analysis periods (default 30 days)
- **Comprehensive Reporting**: Shows both used and unused controller actions
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
  
  # Redis key prefix for storing action usage data
  config.redis_key_prefix = 'routes_analyzer'
  
  # Timeframe for action usage analysis in days
  config.timeframe = 30
end
```

Alternatively, you can create the configuration file manually in `config/initializers/routes_analyzer.rb`.

### Configuration Options

- **redis_url**: The Redis connection URL (required)
- **redis_key_prefix**: Prefix for Redis keys to avoid conflicts (default: "routes_analyzer")
- **timeframe**: Number of days to consider for "recent" usage (default: 30)

## Usage

Once installed and configured, the middleware will automatically start tracking controller action usage. No additional code changes are required.

### Rake Tasks

#### View Controller Action Usage Statistics

```bash
bundle exec rake routes:analyzer:usage
```

This command shows:
- All controller actions available in your application
- Usage count for each action in the specified timeframe
- Last access timestamp
- Summary statistics (total, used, unused actions)

Example output:
```
Controller Action Usage Analysis (30 days)
================================================================================

COUNT    CONTROLLER#ACTION                        METHOD          LAST ACCESSED
--------------------------------------------------------------------------------
45       users#index                              GET             2025-06-18 14:30
23       users#show                               GET             2025-06-18 12:15
12       posts#index                              GET             2025-06-17 09:45
5        posts#create                             POST            2025-06-16 16:20
0        admin/reports#index                      GET             Never
0        api/v1/health#check                      GET             Never

Total actions: 6
Used actions: 4
Unused actions: 2
```

#### Clear Usage Data

```bash
bundle exec rake routes:analyzer:clear
```

Removes all stored controller action usage data from Redis.

#### Check Configuration

```bash
bundle exec rake routes:analyzer:config
```

Displays current configuration and tests Redis connectivity.

## How It Works

1. **Middleware Integration**: The plugin automatically adds middleware to your Rails application
2. **Controller Action Filtering**: Only controller actions from defined routes in `routes.rb` are tracked. This ensures that:
   - Undefined routes (404 errors) are not tracked
   - Catch-all routes that handle unknown paths don't pollute the data
   - Only legitimate application controller actions are analyzed
3. **Request Tracking**: Each valid HTTP request is analyzed to extract controller and action information
4. **Redis Storage**: Usage data is stored in Redis with the following structure:
   - Controller name and action name
   - Access count within the timeframe
   - Last access timestamp
5. **Data Expiration**: Redis keys automatically expire after the configured timeframe plus a buffer period

## Route Detection

The middleware uses Rails' routing system to determine if a route is valid:

- **Path Parameters Check**: Verifies that Rails recognized the route and set path parameters
- **Route Recognition**: Uses `Rails.application.routes.recognize_path` to confirm the route exists in `routes.rb`
- **Error Handling**: Gracefully handles routing errors and invalid requests without tracking them

This approach ensures that only routes you've intentionally defined are included in the usage analysis.

## Controller Action Tracking

The gem tracks usage by controller and action rather than by specific URL paths. This provides more meaningful insights into which parts of your application are being used:

- **Route Definition**: `resources :users` in `routes.rb`
- **Actual Requests**: `GET /users/123`, `GET /users/456`, `POST /users/789/update`
- **Tracked As**: Separate entries for `users#show` and `users#update` actions

This means that accessing different user IDs (e.g., `/users/123`, `/users/456`, `/users/789`) will all be counted under the same `users#show` action, giving you a clear picture of which controller actions are being utilized.

**Example Output:**
```
COUNT    CONTROLLER#ACTION       METHOD    LAST ACCESSED
--------------------------------------------------------------
15       users#show              GET       2025-06-18 14:30
8        users#update            PATCH     2025-06-18 12:15
23       posts#show              GET       2025-06-17 09:45
```

This grouping provides much more meaningful insights into which parts of your application are being used.

## Data Structure

For each tracked controller action, the following data is stored in Redis:

```ruby
{
  controller: "users",           # Controller name
  action: "show",                # Action name
  method: "GET",                 # HTTP method (for reference)
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
