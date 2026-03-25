# frozen_string_literal: true

require "zeitwerk"
require "singleton"
require "manticore-client"

module ManticoreRails
  @circuit_mutex = Mutex.new
  @failure_count = 0

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def auto_indexing?
      return false if Thread.current[:manticore_no_auto_indexing]

      configuration.auto_indexing
    end

    # Temporarily disables auto-indexing for the duration of the block.
    # Thread-safe — only affects the current thread.
    def no_auto_indexing
      was = Thread.current[:manticore_no_auto_indexing]
      Thread.current[:manticore_no_auto_indexing] = true
      yield
    ensure
      Thread.current[:manticore_no_auto_indexing] = was
    end

    def registry
      Registry.instance
    end

    def circuit_open?
      @circuit_mutex.synchronize { @failure_count >= configuration.circuit_breaker_threshold }
    end

    def record_failure!
      @circuit_mutex.synchronize { @failure_count += 1 }
    end

    def record_success!
      @circuit_mutex.synchronize { @failure_count = 0 }
    end

    alias reset_circuit! record_success!

    # Returns false if ManticoreSearch is unreachable.
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
