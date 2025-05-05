# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.push_dir(__dir__, namespace: Manticore)
loader.push_dir(__dir__ + "/client/api", namespace: Manticore::Client)
loader.push_dir(__dir__ + "/client/models", namespace: Manticore::Client)
loader.setup

module Manticore::Client
  class << self
    # Customize default settings for the SDK using block.
    #   Manticore::Client.configure do |config|
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

loader.eager_load
