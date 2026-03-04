# frozen_string_literal: true

require "zeitwerk"
require "singleton"

module ManticoreClient
  module Rails
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def auto_indexing?
        configuration.auto_indexing
      end

      def no_auto_indexing
        old = configuration.auto_indexing
        configuration.auto_indexing = false
        yield
      ensure
        configuration.auto_indexing = old
      end

      def registry
        Registry.instance
      end
    end
  end
end

# Set up separate Zeitwerk loader for ManticoreClient::Rails namespace
rails_loader = Zeitwerk::Loader.new
rails_loader.tag = "manticore-rails"
rails_loader.push_dir(File.expand_path("manticore-rails", __dir__), namespace: ManticoreClient::Rails)
rails_loader.ignore(File.expand_path("manticore-rails/railtie.rb", __dir__))
rails_loader.setup
