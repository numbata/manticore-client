# frozen_string_literal: true

module ManticoreClient
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load File.expand_path("../tasks/manticore.rake", __dir__)
      end
    end
  end
end
