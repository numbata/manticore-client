# frozen_string_literal: true

module ManticoreRails
  class Indexer
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def serialize(record)
      return record.manticore_serialize if record.respond_to?(:manticore_serialize)

      doc = { "id" => record.id }

      index.indexable_fields.each do |field|
        doc[field.name.to_s] = extract_field_value(record, field)
      end

      index.indexable_attributes.each do |attr|
        doc[attr.name.to_s] = coerce_attribute(extract_field_value(record, attr), attr)
      end

      doc.compact
    end

    def index_records(ids)
      scope = index.model_class.where(id: ids)
      associations = index.referenced_associations
      scope = scope.includes(*associations) if associations.any?

      docs = scope.map { |r| serialize(r) }
      bulk_replace(docs)
    end

    def delete_records(ids)
      return if ids.empty?

      ndjson = ids.map do |id|
        { delete: { index: index.table_name, id: id } }.to_json
      end.join("\n")

      index_api.bulk(ndjson)
    end

    def reindex_all(scope: nil, &block)
      batch_size = ManticoreRails.configuration.batch_size
      source = scope || index.model_class
      associations = index.referenced_associations

      total = 0
      source = source.includes(*associations) if associations.any?
      source.find_in_batches(batch_size: batch_size) do |batch|
        docs = batch.map { |r| serialize(r) }
        bulk_replace(docs)
        total += docs.size
        block&.call(total)
      end
      total
    end

    MAX_ASSOCIATION_DEPTH = 10

    private

      def extract_field_value(record, field)
        if field.sql?
          nil
        elsif field.association?
          extract_association_value(record, field)
        else
          record.public_send(field.column_name)
        end
      end

      # NOTE: Association values are always joined into a space-separated string.
      # This is appropriate for full-text fields but means association-backed
      # attributes (e.g. datetime or integer) will be coerced as strings.
      # Use manticore_serialize for typed association attributes.
      def extract_association_value(record, field)
        path = field.association_path
        col = path.last
        navigations = path[0...-1]

        values = collect_values(record, navigations, col)
        return nil if values.nil? || values.empty?

        values.compact.join(" ")
      end

      def collect_values(target, navigations, col, depth = 0)
        return nil if target.nil?
        raise "Circular association detected (depth > #{MAX_ASSOCIATION_DEPTH})" if depth > MAX_ASSOCIATION_DEPTH

        return [target.public_send(col)] if navigations.empty?

        current_assoc = navigations.first
        remaining = navigations[1..]
        result = target.public_send(current_assoc)
        return nil if result.nil?

        if result.respond_to?(:flat_map)
          result.flat_map { |item| collect_values(item, remaining, col, depth + 1) || [] }
        else
          collect_values(result, remaining, col, depth + 1)
        end
      end

      def coerce_attribute(value, attr)
        case value
        when Time, DateTime
          value.to_i
        when TrueClass
          1
        when FalseClass
          0
        when NilClass
          %i[integer bigint timestamp].include?(attr.manticore_type) ? 0 : nil
        else
          value
        end
      end

      def bulk_replace(docs)
        return if docs.empty?

        ndjson = docs.map do |doc|
          id = doc["id"] || doc[:id]
          rest = doc.reject { |k, _| k.to_s == "id" }
          { replace: { index: index.table_name, id: id, doc: rest } }.to_json
        end.join("\n")

        index_api.bulk(ndjson)
      end

      def index_api
        @index_api ||= ManticoreClient::Client::IndexApi.new
      end
  end
end
