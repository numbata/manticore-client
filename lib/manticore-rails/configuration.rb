# frozen_string_literal: true

module ManticoreRails
  class Configuration
    attr_accessor :auto_indexing, :async_indexing, :circuit_breaker_threshold
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

    def batch_size=(value)
      value = value.to_i
      raise ArgumentError, "batch_size must be positive" unless value.positive?

      @batch_size = value
    end

    def index_prefix=(value)
      if value && !value.to_s.match?(/\A[a-z0-9_]*\z/i)
        raise ArgumentError, "index_prefix must only contain alphanumeric characters and underscores"
      end

      @index_prefix = value&.to_s
    end

    def on_error=(value)
      @on_error = case value
                  when :raise
                    ->(_message, error) { raise error }
                  else
                    value
      end
    end

    def index_job_class=(value)
      @index_job_class = value
      @resolved_job_class = nil
    end

    def resolved_job_class
      @resolved_job_class ||= case @index_job_class
                              when String then @index_job_class.constantize
                              else @index_job_class
      end
    end

    def table_name_for(name)
      [index_prefix, name].compact.join
    end
  end
end
