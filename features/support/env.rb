# frozen_string_literal: true

require "bundler/setup"
require "buildah"
require "rspec/expectations"

# Configure RSpec for use with Cucumber
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

# Clean up after each scenario
After do
  # Reset any mocks or stubs
  RSpec::Mocks.teardown if defined?(RSpec::Mocks)
end

Before do
  # Set up fresh mocks for each scenario
  RSpec::Mocks.setup if defined?(RSpec::Mocks)
end

