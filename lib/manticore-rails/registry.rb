# frozen_string_literal: true

module ManticoreRails
  class Registry
    include Singleton

    def initialize
      @mutex = Mutex.new
      @indexes = {}
    end

    def register(klass, index)
      @mutex.synchronize { @indexes[klass] = index }
    end

    def all
      @mutex.synchronize { @indexes.values }
    end

    def find_by_class(klass)
      @mutex.synchronize { @indexes[klass] }
    end

    def find_by_table(table_name)
      @mutex.synchronize { @indexes.values.find { |i| i.table_name == table_name } }
    end

    def reset!
      @mutex.synchronize { @indexes.clear }
    end
  end
end
