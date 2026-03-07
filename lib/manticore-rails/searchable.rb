# frozen_string_literal: true

require "set"

module ManticoreRails
  # ActiveRecord concern that adds ManticoreSearch indexing and search
  # capabilities to a model. Include this module and call
  # {ClassMethods#define_manticore_index} to configure the index.
  #
  # @example
  #   class Article < ApplicationRecord
  #     include ManticoreRails::Searchable
  #
  #     define_manticore_index do
  #       indexes :title, :body
  #       has :status, type: :integer
  #     end
  #   end
  module Searchable
    def self.included(base)
      base.extend ClassMethods
    end

    # Class-level DSL methods mixed into the including model.
    module ClassMethods
      # Defines the ManticoreSearch index for this model using a block DSL.
      # Registers the index in the global {Registry} and sets up
      # +after_commit+ callbacks for automatic indexing.
      #
      # @yield DSL block evaluated by {IndexBuilder}
      def define_manticore_index(&block)
        builder = IndexBuilder.new(&block)
        index = builder.build(self)

        validate_manticore_associations(index) if respond_to?(:reflect_on_association)

        ManticoreRails.registry.register(self, index)

        # Set up after_commit callbacks if the model supports them
        if respond_to?(:after_commit)
          after_commit :manticore_index_record, on: %i[create update]
          after_commit :manticore_remove_record, on: :destroy
        end

        # Set up association reindex callbacks
        setup_manticore_reindex_callbacks(index)
      end

      # Returns the {Index} definition for this model, walking STI ancestors
      # if needed.
      # @return [Index, nil]
      def manticore_index
        ManticoreRails.registry.find_by_class(self)
      end

      # Returns a new {Indexer} for this model's index.
      # @return [Indexer]
      def manticore_indexer
        Indexer.new(manticore_index)
      end

      # Performs a full-text search returning hydrated ActiveRecord records.
      # @param query [String] search query
      # @param options [Hash] search options (+:with+, +:without+, +:order+, +:page+, +:per_page+)
      # @return [Searcher::Result]
      def search(query, options = {})
        Searcher.search(manticore_index, query, options)
      end

      # Performs a full-text search returning only record IDs.
      # @param query [String] search query
      # @param options [Hash] search options (same as {#search})
      # @return [Searcher::Result]
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
              after_commit(on: %i[create update destroy]) do
                result = send(inverse_name)
                if result.respond_to?(:find_each)
                  result.find_each { |r| r.manticore_index_record if r.respond_to?(:manticore_index_record) }
                elsif result.respond_to?(:manticore_index_record)
                  result.manticore_index_record
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

    # Indexes this record in ManticoreSearch. Called automatically via
    # +after_commit+ on create/update. Respects circuit breaker and
    # auto-indexing settings.
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

    # Removes this record from ManticoreSearch. Called automatically via
    # +after_commit+ on destroy. Respects circuit breaker and
    # auto-indexing settings.
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

      # In async mode, the block is NOT executed — only the job is enqueued.
      # Circuit breaker calls belong inside the block so they only fire
      # on actual sync execution.
      def manticore_perform_async_or_sync(action)
        config = ManticoreRails.configuration
        if config.async_indexing && config.index_job_class
          config.resolved_job_class.perform_later(action.to_s, self.class.name, id)
        else
          yield
        end
      end

      def manticore_should_index?
        ManticoreRails.auto_indexing? && !ManticoreRails.circuit_open? && !self.class.manticore_index.nil?
      end
  end
end
