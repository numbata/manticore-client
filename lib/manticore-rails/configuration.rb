# frozen_string_literal: true

module ManticoreClient
  module Rails
    class Configuration
      attr_accessor :index_prefix, :batch_size, :auto_indexing, :async_indexing, :index_job_class

      def initialize
        @index_prefix = nil
        @batch_size = 1000
        @auto_indexing = true
        @async_indexing = false
        @index_job_class = nil
      end

      def table_name_for(name)
        [index_prefix, name].compact.join
      end
    end
  end
end
