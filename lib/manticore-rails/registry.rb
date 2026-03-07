# frozen_string_literal: true

module ManticoreRails
  class Registry
    include Singleton

    def initialize
      @mutex = Mutex.new
      @indexes = {}
      @by_table = {}
    end

    def register(klass, index)
      index.freeze!
      @mutex.synchronize do
        @indexes[klass] = index
        @by_table[index.table_name] = index
      end
    end

    def all
      @mutex.synchronize { @indexes.values }
    end

    def find_by_class(klass)
      @mutex.synchronize do
        @indexes[klass] || klass.ancestors.drop(1).lazy.filter_map { |a| @indexes[a] }.first
      end
    end

    def find_by_table(table_name)
      @mutex.synchronize { @by_table[table_name] }
    end

    def reset!
      @mutex.synchronize do
        @indexes.clear
        @by_table.clear
      end
    end
  end
end
