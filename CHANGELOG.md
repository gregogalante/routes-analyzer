# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of Routes::Analyzer plugin
- Middleware for automatic route usage tracking
- Redis integration for storing route access statistics
- Configuration system with Redis URL, key prefix, and timeframe options
- Route usage tracker with comprehensive statistics
- Rake tasks for analyzing route usage, clearing data, and checking configuration
- Ability to show defined routes even when Redis is not configured
- Comprehensive test suite
- Documentation and examples

### Features
- **Route Usage Tracking**: Automatically tracks which routes are accessed and how often
- **Redis Storage**: Uses Redis to store usage statistics efficiently  
- **Configurable Timeframe**: Set custom analysis periods (default 30 days)
- **Comprehensive Reporting**: Shows both used and unused routes with detailed statistics
- **Easy Integration**: Automatic middleware registration through Rails Railtie
- **Flexible Configuration**: Environment-based configuration with sensible defaults
- **Error Handling**: Graceful fallbacks when Redis is unavailable

### Rake Tasks
- `routes:analyzer:usage` - Show routes usage statistics
- `routes:analyzer:clear` - Clear all routes usage data  
- `routes:analyzer:config` - Show current configuration and test Redis connectivity
