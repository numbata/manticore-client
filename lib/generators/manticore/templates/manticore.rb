# frozen_string_literal: true

ManticoreClient::Client.configure do |config|
  config.host = ENV.fetch("MANTICORESEARCH_URI", "http://127.0.0.1:9308")
end

ManticoreRails.configure do |config|
  config.index_prefix    = Rails.env.test? ? "test" : nil
  config.batch_size      = 1000
  config.auto_indexing   = true
  config.async_indexing  = false
  # config.index_job_class           = "ManticoreIndexJob"
  # config.circuit_breaker_threshold = 10
  # config.on_error = ->(msg, err) { Rails.logger.error("[ManticoreRails] #{msg}: #{err.message}") }
  config.on_error = :raise unless Rails.env.production?
end
