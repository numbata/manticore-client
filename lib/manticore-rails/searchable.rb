# frozen_string_literal: true

module ManticoreRails
  module Searchable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def define_manticore_index(&block)
        builder = IndexBuilder.new(&block)
        index = builder.build(self)

        ManticoreRails.registry.register(self, index)

        # Set up after_commit callbacks if the model supports them
        if respond_to?(:after_commit)
          after_commit :manticore_index_record, on: %i[create update]
          after_commit :manticore_remove_record, on: :destroy
        end

        # Set up association reindex callbacks
        setup_manticore_reindex_callbacks(index)
      end

      def manticore_index
        ManticoreRails.registry.find_by_class(self)
      end

      def manticore_indexer
        Indexer.new(manticore_index)
      end

      def search(query, options = {})
        Searcher.search(manticore_index, query, options)
      end

      def search_for_ids(query, options = {})
        Searcher.search_for_ids(manticore_index, query, options)
      end

      private

      def setup_manticore_reindex_callbacks(index)
        return unless respond_to?(:reflect_on_association)

        index.reindex_associations.each do |assoc_name|
          reflection = reflect_on_association(assoc_name.to_sym)
          next unless reflection

          inverse = reflection.inverse_of
          next unless inverse

          inverse_name = inverse.name

          reflection.klass.class_eval do
            after_commit(on: %i[create update destroy]) do
              parent = send(inverse_name)
              parent&.manticore_index_record if parent&.respond_to?(:manticore_index_record)
            end
          end
        rescue => e
          # Log but don't fail if callback setup doesn't work
          warn "[ManticoreRails] Failed to setup reindex callback for #{assoc_name}: #{e.message}"
        end
      end
    end

    def manticore_index_record
      return unless manticore_should_index?

      config = ManticoreRails.configuration
      if config.async_indexing && config.index_job_class
        job_class = config.index_job_class.is_a?(String) ? config.index_job_class.constantize : config.index_job_class
        job_class.perform_later(self.class.name, id)
      else
        self.class.manticore_indexer.index_records([id])
      end
    rescue => e
      warn "[ManticoreRails] Failed to index #{self.class.name}##{id}: #{e.message}"
    end

    def manticore_remove_record
      return unless manticore_should_index?

      self.class.manticore_indexer.delete_records([id])
    rescue => e
      warn "[ManticoreRails] Failed to remove #{self.class.name}##{id}: #{e.message}"
    end

    def manticore_should_index?
      ManticoreRails.auto_indexing? && !self.class.manticore_index.nil?
    end
  end
end
