# frozen_string_literal: true

module ManticoreRails
  # Thread-safe singleton registry that maps ActiveRecord model classes
  # to their {Index} definitions. Supports STI by walking ancestor chains.
  #
  # @example
  #   ManticoreRails.registry.find_by_class(Article)  #=> #<Index ...>
  #   ManticoreRails.registry.all                     #=> [#<Index ...>, ...]
  class Registry
    include Singleton

    def initialize
      @mutex = Mutex.new
      @indexes = {}
      @by_table = {}
    end

    # Registers an index for a model class. Freezes the index to prevent
    # further modification.
    # @param klass [Class] the ActiveRecord model class
    # @param index [Index] the index definition to register
    def register(klass, index)
      index.freeze!
      @mutex.synchronize do
        @indexes[klass] = index
        @by_table[index.table_name] = index
      end
    end

    # Returns all registered index definitions.
    # @return [Array<Index>]
    def all
      @mutex.synchronize { @indexes.values }
    end

    # Finds the index for a model class, walking STI ancestors if the
    # exact class has no registered index.
    # @param klass [Class] the model class to look up
    # @return [Index, nil]
    def find_by_class(klass)
      @mutex.synchronize do
        @indexes[klass] || klass.ancestors.drop(1).lazy.filter_map { |a| @indexes[a] }.first
      end
    end

    # Finds an index by its ManticoreSearch table name.
    # @param table_name [String] the table name (including prefix)
    # @return [Index, nil]
    def find_by_table(table_name)
      @mutex.synchronize { @by_table[table_name] }
    end

    # Removes all registered indexes. Primarily used in tests.
    def reset!
      @mutex.synchronize do
        @indexes.clear
        @by_table.clear
      end
    end
  end
end
