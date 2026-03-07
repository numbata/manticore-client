# frozen_string_literal: true

require "zeitwerk"
require "singleton"
require "manticore-client"

# ActiveRecord integration for ManticoreSearch with a ThinkingSphinx-style DSL.
#
# @example Configuration
#   ManticoreRails.configure do |config|
#     config.index_prefix = Rails.env.test? ? "test_" : nil
#     config.auto_indexing = true
#   end
#
# @example Search
#   Article.search("ruby", with: { status: 1 }, page: 1, per_page: 20)
module ManticoreRails
  @circuit_mutex = Mutex.new
  @failure_count = 0

  class << self
    # Returns the global configuration instance.
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the global configuration for modification.
    # @yieldparam config [Configuration]
    def configure
      yield(configuration)
    end

    # Whether auto-indexing is currently active for the current thread.
    # @return [Boolean]
    def auto_indexing?
      return false if Thread.current[:manticore_no_auto_indexing]

      configuration.auto_indexing
    end

    # Temporarily disables auto-indexing for the duration of the block.
    # Thread-safe — only affects the current thread.
    # @yield Block during which auto-indexing is suppressed
    def no_auto_indexing
      was = Thread.current[:manticore_no_auto_indexing]
      Thread.current[:manticore_no_auto_indexing] = true
      yield
    ensure
      Thread.current[:manticore_no_auto_indexing] = was
    end

    # Returns the global index registry.
    # @return [Registry]
    def registry
      Registry.instance
    end

    # Whether the circuit breaker has tripped due to consecutive failures.
    # @return [Boolean]
    def circuit_open?
      @circuit_mutex.synchronize { @failure_count >= configuration.circuit_breaker_threshold }
    end

    # Records a failed indexing attempt. Thread-safe.
    def record_failure!
      @circuit_mutex.synchronize { @failure_count += 1 }
    end

    # Records a successful indexing attempt, resetting the failure counter. Thread-safe.
    def record_success!
      @circuit_mutex.synchronize { @failure_count = 0 }
    end

    # Manually resets the circuit breaker. Alias for {record_success!}.
    alias reset_circuit! record_success!

    # Checks if ManticoreSearch is reachable.
    # @return [Boolean] true if the server responds, false on any error
    def healthy?
      client = ManticoreClient::Client::UtilsApi.new
      response = client.sql("query=SHOW+STATUS", query_params: { mode: "raw" })
      response.is_a?(Array) && !response.empty?
    rescue StandardError
      false
    end
  end
end

# Set up separate Zeitwerk loader for ManticoreRails namespace
rails_loader = Zeitwerk::Loader.new
rails_loader.tag = "manticore-rails"
rails_loader.push_dir(File.expand_path("manticore-rails", __dir__), namespace: ManticoreRails)
rails_loader.ignore(File.expand_path("manticore-rails/railtie.rb", __dir__))
rails_loader.ignore(File.expand_path("manticore-rails/version.rb", __dir__))
rails_loader.setup

require_relative "manticore-rails/version"

require_relative "manticore-rails/railtie" if defined?(Rails::Railtie)
