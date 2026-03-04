# frozen_string_literal: true

require "zeitwerk"

module ManticoreClient
  # The Manticore Search client for Ruby.
  module Client
  end
end

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.push_dir(__dir__, namespace: ManticoreClient)
loader.push_dir("#{__dir__}/client/api", namespace: ManticoreClient::Client)
loader.push_dir("#{__dir__}/client/models", namespace: ManticoreClient::Client)
loader.setup

module ManticoreClient
  module Client
    class << self
      # Customize default settings for the SDK using block.
      #   ManticoreClient::Client.configure do |config|
      #     config.username = "xxx"
      #     config.password = "xxx"
      #   end
      # If no block given, return the default Configuration object.
      def configure
        if block_given?
          yield(Configuration.default)
        else
          Configuration.default
        end
      end
    end
  end
end

loader.eager_load
