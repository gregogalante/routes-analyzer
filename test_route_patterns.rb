#!/usr/bin/env ruby

# Simple test script to verify route pattern tracking
# This script manually tests the extract_route_info method

require_relative 'lib/routes/analyzer'
require_relative 'test/dummy/config/environment'

# Mock middleware for testing
middleware = Routes::Analyzer::Middleware.new(->(env) { [ 200, {}, [ "OK" ] ] })

# Test cases
test_cases = [
  {
    name: "User show route with ID 123",
    env: {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/users/123",
      "action_controller.instance" => Class.new do
        def action_name; "show"; end
        def controller_name; "users"; end
      end.new,
      "action_dispatch.request.path_parameters" => {
        controller: "users", action: "show", id: "123"
      }
    },
    expected_route: "/users/:id"
  },
  {
    name: "User show route with ID 456",
    env: {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/users/456",
      "action_controller.instance" => Class.new do
        def action_name; "show"; end
        def controller_name; "users"; end
      end.new,
      "action_dispatch.request.path_parameters" => {
        controller: "users", action: "show", id: "456"
      }
    },
    expected_route: "/users/:id"
  },
  {
    name: "User profile route",
    env: {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/users/789/profile",
      "action_controller.instance" => Class.new do
        def action_name; "profile"; end
        def controller_name; "users"; end
      end.new,
      "action_dispatch.request.path_parameters" => {
        controller: "users", action: "profile", id: "789"
      }
    },
    expected_route: "/users/:id/profile"
  },
  {
    name: "Posts index route",
    env: {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/posts",
      "action_controller.instance" => Class.new do
        def action_name; "index"; end
        def controller_name; "posts"; end
      end.new,
      "action_dispatch.request.path_parameters" => {
        controller: "posts", action: "index"
      }
    },
    expected_route: "/posts"
  }
]

puts "Testing route pattern extraction..."
puts "=" * 50

test_cases.each do |test_case|
  request = Rack::Request.new(test_case[:env])
  route_info = middleware.send(:extract_route_info, test_case[:env], request)

  puts "\n#{test_case[:name]}:"
  puts "  Input path: #{test_case[:env]['PATH_INFO']}"
  puts "  Expected pattern: #{test_case[:expected_route]}"
  puts "  Actual pattern: #{route_info[:route]}"

  if route_info[:route] == test_case[:expected_route]
    puts "  ✅ PASS"
  else
    puts "  ❌ FAIL"
  end
end

puts "\n" + "=" * 50
puts "Test completed!"
