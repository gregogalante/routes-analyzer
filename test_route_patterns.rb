#!/usr/bin/env ruby

# Simple test script to verify controller#action tracking
# This script manually tests the extract_route_info method

require_relative 'lib/routes/analyzer'
require_relative 'test/dummy/config/environment'

# Mock middleware for testing
middleware = Routes::Analyzer::Middleware.new(->(env) { [ 200, {}, [ "OK" ] ] })

# Test cases
test_cases = [
  {
    name: "User show action with ID 123",
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
    expected_controller: "users",
    expected_action: "show"
  },
  {
    name: "User show action with ID 456",
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
    expected_controller: "users",
    expected_action: "show"
  },
  {
    name: "User profile action",
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
    expected_controller: "users",
    expected_action: "profile"
  },
  {
    name: "Posts index action",
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
    expected_controller: "posts",
    expected_action: "index"
  }
]

puts "Testing controller#action extraction..."
puts "=" * 50

test_cases.each do |test_case|
  request = Rack::Request.new(test_case[:env])
  route_info = middleware.send(:extract_route_info, test_case[:env], request)

  puts "\n#{test_case[:name]}:"
  puts "  Input path: #{test_case[:env]['PATH_INFO']}"
  puts "  Expected controller#action: #{test_case[:expected_controller]}##{test_case[:expected_action]}"
  puts "  Actual controller#action: #{route_info[:controller]}##{route_info[:action]}"

  if route_info[:controller] == test_case[:expected_controller] && route_info[:action] == test_case[:expected_action]
    puts "  ✅ PASS"
  else
    puts "  ❌ FAIL"
  end
end

puts "\n" + "=" * 50
puts "Test completed!"
