# frozen_string_literal: true

require "rails/generators"

module Manticore
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a ManticoreRails initializer"

      def copy_initializer
        template "manticore.rb", "config/initializers/manticore.rb"
      end
    end
  end
end
