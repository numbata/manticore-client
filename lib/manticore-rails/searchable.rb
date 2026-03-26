# frozen_string_literal: true

require "set"

module ManticoreRails
  module Searchable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def define_manticore_index(&block)
        builder = IndexBuilder.new(&block)
        index = builder.build(self)

        validate_manticore_associations(index) if respond_to?(:reflect_on_association)

        ManticoreRails.registry.register(self, index)

        unless @manticore_callbacks_registered
          @manticore_callbacks_registered = true
          if respond_to?(:after_commit)
            after_commit :manticore_index_record, on: %i[create update]
            after_commit :manticore_remove_record, on: :destroy
          end
        end

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

        def validate_manticore_associations(index)
          (index.fields + index.attributes).select(&:association?).each do |field|
            root = field.association_name
            next if reflect_on_association(root)

            warn "[ManticoreRails] WARNING: #{name} references unknown association '#{root}' " \
                 "in field '#{field.column}'. Typo?"
          end
        end

        def setup_manticore_reindex_callbacks(index)
          return unless respond_to?(:reflect_on_association)

          seen = Set.new
          index.reindex_associations.each do |assoc_name|
            root_assoc = assoc_name.to_s.split(".").first
            next unless seen.add?(root_assoc)

            reflection = reflect_on_association(root_assoc.to_sym)
            next unless reflection

            inverse = reflection.inverse_of
            next unless inverse

            inverse_name = inverse.name

            reflection.klass.class_eval do
              @manticore_reindex_callbacks ||= Set.new
              if @manticore_reindex_callbacks.add?(inverse_name)
                after_commit(on: %i[create update destroy]) do
                  result = send(inverse_name)
                  if result.respond_to?(:find_each)
                    result.find_each { |r| r.manticore_index_record if r.respond_to?(:manticore_index_record) }
                  elsif result.respond_to?(:manticore_index_record)
                    result.manticore_index_record
                  end
                end
              end
            end
          rescue StandardError => e
            ManticoreRails.configuration.on_error&.call(
              "Failed to setup reindex callback for #{assoc_name}", e
            )
          end
        end
    end

    def manticore_index_record
      return unless manticore_should_index?

      manticore_perform_async_or_sync(:index) do
        self.class.manticore_indexer.index_records([id])
        ManticoreRails.record_success!
      end
    rescue StandardError => e
      ManticoreRails.record_failure!
      ManticoreRails.configuration.on_error&.call(
        "Failed to index #{self.class.name}##{id}", e
      )
    end

    def manticore_remove_record
      return unless manticore_should_index?

      manticore_perform_async_or_sync(:delete) do
        self.class.manticore_indexer.delete_records([id])
        ManticoreRails.record_success!
      end
    rescue StandardError => e
      ManticoreRails.record_failure!
      ManticoreRails.configuration.on_error&.call(
        "Failed to remove #{self.class.name}##{id}", e
      )
    end

    private

      def manticore_perform_async_or_sync(action)
        config = ManticoreRails.configuration
        if config.async_indexing && config.index_job_class
          config.resolved_job_class.perform_later(action.to_s, self.class.name, id)
        else
          yield
        end
      end

      def manticore_should_index?
        ManticoreRails.auto_indexing? && !ManticoreRails.circuit_open? && !!self.class.manticore_index
      end
  end
end
