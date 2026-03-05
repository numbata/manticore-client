# frozen_string_literal: true

module ManticoreClient
  module Rails
    class Indexer
      attr_reader :index

      def initialize(index)
        @index = index
      end

      def serialize(record)
        return record.manticore_serialize if record.respond_to?(:manticore_serialize)

        doc = { "id" => record.id }

        index.fields.each do |field|
          doc[field.name.to_s] = extract_field_value(record, field)
        end

        index.attributes.each do |attr|
          doc[attr.name.to_s] = coerce_attribute(extract_field_value(record, attr), attr)
        end

        doc.compact
      end

      def index_records(ids)
        records = index.model_class
          .where(id: ids)
          .includes(*index.referenced_associations)

        docs = records.map { |r| serialize(r) }
        bulk_replace(docs)
      end

      def delete_records(ids)
        api = ManticoreClient::Client::IndexApi.new
        ids.each do |id|
          request = ManticoreClient::Client::DeleteDocumentRequest.new(
            table: index.table_name,
            id: id
          )
          api.delete(request)
        end
      end

      def reindex_all(scope: nil, &block)
        batch_size = ManticoreClient::Rails.configuration.batch_size
        source = scope || index.model_class
        associations = index.referenced_associations

        total = 0
        source.includes(*associations).find_in_batches(batch_size: batch_size) do |batch|
          docs = batch.map { |r| serialize(r) }
          bulk_replace(docs)
          total += docs.size
          block&.call(total)
        end
        total
      end

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

      def extract_association_value(record, field)
        # association_path: "tags.name" → [:tags, :name], "anchors.dvags.name" → [:anchors, :dvags, :name]
        # Walk all parts except the last (column_name), collecting from record
        path = field.association_path
        col = path.last
        navigations = path[0...-1]

        # Recursively navigate, handling both single objects and collections
        values = collect_values(record, navigations, col)
        return nil if values.nil? || values.empty?

        values.compact.join(" ")
      end

      def collect_values(target, navigations, col)
        return nil if target.nil?

        if navigations.empty?
          # Leaf: extract the column value
          return [target.public_send(col)]
        end

        current_assoc = navigations.first
        remaining = navigations[1..]
        result = target.public_send(current_assoc)
        return nil if result.nil?

        if result.respond_to?(:flat_map)
          # Collection
          result.flat_map { |item| collect_values(item, remaining, col) || [] }
        else
          # Single object
          collect_values(result, remaining, col)
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
          body = { replace: { index: index.table_name, id: doc["id"], doc: doc.except("id") } }
          body.to_json
        end.join("\n")

        api = ManticoreClient::Client::IndexApi.new
        api.bulk(ndjson)
      end
    end
  end
end
