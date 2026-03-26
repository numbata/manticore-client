require "manticore/client"
require "uri"
require "json"
require "net/http"
require "pry"
require_relative "support/manticore_sql_helper"

# Table prefix for all test indexes; configurable via ENV
TABLE_PREFIX = ENV["MANTICORE_TEST_PREFIX"] || "test_"

# Configure ManticoreClient::Client from MANTICORESEARCH_URI or default
uri = ENV["MANTICORESEARCH_URI"] || "http://127.0.0.1:9308"
parsed = URI.parse(uri)

unless parsed.host && parsed.port
  abort "\n[ERROR] MANTICORESEARCH_URI must specify a valid host and port. Got: #{uri}\n"
end

ManticoreClient::Client.configure do |config|
  config.host = "#{parsed.scheme}://#{parsed.host}:#{parsed.port}"
  config.username = parsed.user if parsed.user
  config.password = parsed.password if parsed.password
  config.debugging = ENV["DEBUG"] == "true"
end

# Optionally, check if the server is available before running specs
begin
  Net::HTTP.start(parsed.host, parsed.port, read_timeout: 2) do |http|
    http.head("/")
  end
rescue StandardError => e
  abort "\n[ERROR] Could not connect to ManticoreClient at #{parsed.host}:#{parsed.port}. " \
        "Is it running? (#{e.class}: #{e.message})\n"
end

# Detect whether the server supports dev-only endpoints (e.g. /autocomplete, /_update/:id).
# Stable Manticore builds return 501 for these; the :dev_only tag skips them automatically.
MANTICORE_DEV_ENDPOINTS = begin
  req = Net::HTTP::Post.new("/autocomplete")
  req["Content-Type"] = "application/json"
  req.body = "{}"
  res = Net::HTTP.start(parsed.host, parsed.port, read_timeout: 2) { |http| http.request(req) }
  res.code.to_i != 501
rescue StandardError
  false
end

RSpec.configure do |config|
  config.before(:suite) do
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

  config.around(:example, :dev_only) do |example|
    if MANTICORE_DEV_ENDPOINTS
      example.run
    else
      skip "requires Manticore dev server (endpoint returned 501 on this build)"
    end
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

RSpec::Matchers.define :have_docs do |expected|
  match do |actual|
    @rows = ManticoreSqlHelper.query("SELECT * FROM #{actual}")
    @rows.any? { |row| row >= expected }
  end

  failure_message do |actual|
    "expected table #{actual} to have a row matching #{expected.inspect}, got: #{@rows.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected table #{actual} not to have a row matching #{expected.inspect}, but it does"
  end
end
