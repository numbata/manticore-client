# frozen_string_literal: true

module ManticoreRails
  # Holds all configuration options for ManticoreRails.
  #
  # @example
  #   ManticoreRails.configure do |config|
  #     config.index_prefix = "test_"
  #     config.on_error = :raise
  #   end
  class Configuration
    # @return [Boolean] whether after_commit callbacks auto-index records (default: true)
    # @return [Boolean] whether indexing is delegated to a background job (default: false)
    # @return [Integer] consecutive failures before circuit breaker opens (default: 10)
    attr_accessor :auto_indexing, :async_indexing, :circuit_breaker_threshold

    # @return [Proc, nil] error handler receiving (message, error)
    # @return [String, Class, nil] job class for async indexing
    # @return [String, nil] prefix prepended to all ManticoreSearch table names
    # @return [Integer] records per batch during reindex (default: 1000)
    attr_reader :on_error, :index_job_class, :index_prefix, :batch_size

    def initialize
      @index_prefix = nil
      @batch_size = 1000
      @auto_indexing = true
      @async_indexing = false
      @index_job_class = nil
      @circuit_breaker_threshold = 10
      @on_error = ->(message, error) { warn "[ManticoreRails] #{message}: #{error.message}" }
    end

    # @param value [Integer] must be positive
    # @raise [ArgumentError] if value is not positive
    def batch_size=(value)
      value = value.to_i
      raise ArgumentError, "batch_size must be positive" unless value.positive?

      @batch_size = value
    end

    # @param value [String, nil] alphanumeric and underscores only
    # @raise [ArgumentError] if value contains invalid characters
    def index_prefix=(value)
      if value && !value.to_s.match?(/\A[a-z0-9_]*\z/i)
        raise ArgumentError, "index_prefix must only contain alphanumeric characters and underscores"
      end

      @index_prefix = value&.to_s
    end

    # Sets the error handler. Pass +:raise+ to re-raise errors in dev/test.
    # @param value [Proc, Symbol, nil] a callable, +:raise+, or nil to disable
    def on_error=(value)
      @on_error = case value
                  when :raise
                    ->(_message, error) { raise error }
                  else
                    value
      end
    end

    # @param value [String, Class, nil] job class or class name for async indexing
    def index_job_class=(value)
      @index_job_class = value
      @resolved_job_class = nil
    end

    # Resolves the job class, constantizing strings on first access.
    # @return [Class, nil]
    def resolved_job_class
      @resolved_job_class ||= case @index_job_class
                              when String then @index_job_class.constantize
                              else @index_job_class
      end
    end

    # Builds a prefixed table name.
    # @param name [String] the base table name
    # @return [String]
    def table_name_for(name)
      [index_prefix, name].compact.join
    end

    # Resets all configuration to defaults.
    def reset!
      initialize
    end
  end
end
