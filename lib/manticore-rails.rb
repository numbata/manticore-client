# frozen_string_literal: true

require "zeitwerk"
require "singleton"
require "manticore-client"

module ManticoreRails
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

    def no_auto_indexing
      Thread.current[:manticore_no_auto_indexing] = true
      yield
    ensure
      Thread.current[:manticore_no_auto_indexing] = false
    end

    def registry
      Registry.instance
    end
  end
end

# Set up separate Zeitwerk loader for ManticoreRails namespace
rails_loader = Zeitwerk::Loader.new
rails_loader.tag = "manticore-rails"
rails_loader.push_dir(File.expand_path("manticore-rails", __dir__), namespace: ManticoreRails)
rails_loader.ignore(File.expand_path("manticore-rails/railtie.rb", __dir__))
rails_loader.setup

require_relative "manticore-rails/railtie" if defined?(::Rails::Railtie)
