require "manticore/client"
require "uri"
require "json"
require "net/http"
require "pry"
require_relative "support/manticore_sql_helper"

# Table prefix for all test indexes; configurable via ENV
TABLE_PREFIX = ENV["MANTICORE_TEST_PREFIX"] || "test_"

# Configure Manticore::Client from MANTICORESEARCH_URI or default
uri = ENV["MANTICORESEARCH_URI"] || "http://127.0.0.1:9308"
parsed = URI.parse(uri)

unless parsed.host && parsed.port
  abort "\n[ERROR] MANTICORESEARCH_URI must specify a valid host and port. Got: #{uri}\n"
end

Manticore::Client.configure do |config|
  config.host = "#{parsed.scheme}://#{parsed.host}:#{parsed.port}"
  config.username = parsed.user if parsed.user
  config.password = parsed.password if parsed.password
  config.debugging = ENV["DEBUG"] == 'true'
end

# Optionally, check if the server is available before running specs
begin
  Net::HTTP.start(parsed.host, parsed.port, read_timeout: 2) do |http|
    http.head("/")
  end
rescue => e
  abort "\n[ERROR] Could not connect to ManticoreSearch at #{parsed.host}:#{parsed.port}. Is it running? (#{e.class}: #{e.message})\n"
end

RSpec.configure do |config|
  config.before(:suite) do
    puts "Using Manticore test index prefix: #{TABLE_PREFIX.inspect}"
    ManticoreSqlHelper.tables(prefix: TABLE_PREFIX).each do |table|
      ManticoreSqlHelper.drop_table(table)
    end
  end

  config.after(:suite) do
    ManticoreSqlHelper.tables(prefix: TABLE_PREFIX).each do |table|
      ManticoreSqlHelper.drop_table(table)
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

# Helper method to check if docs exist in a table
# This matcher checks if the table contains the expected documents
# It queries the table and compares the results with the expected documents
# If the table does not exist or if there are no matching documents, it raises an error
# Usage:
# expect(TABLE_PREFIX + "movies").to have_docs(
#   { id: 1, title: "Scary movie", rating: 9.5 },
#   { id: 3, title: "New movie", rating: 8.5 }
# )
RSpec::Matchers.define :have_docs do |expected|
  match do |actual|
    result = ManticoreSqlHelper.query("SELECT * FROM #{actual}")
    result.any? { |row| row >= expected }
  end

  failure_message do |actual|
    "expected that table #{actual} would have #{expected} rows, but it has #{actual.count}"
  end

  failure_message_when_negated do |actual|
    "expected that table #{actual} would not have #{expected} rows, but it does"
  end
end
