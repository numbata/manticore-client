# frozen_string_literal: true

module ManticoreClient
  module Rails
    class Schema
      MANTICORE_TYPE_MAP = {
        text: "text",
        string: "string",
        bigint: "bigint",
        timestamp: "timestamp",
        bool: "bool",
        float: "float",
        json: "json",
        mva: "multi"
      }.freeze

      class << self
        def create_table(index)
          execute(create_table_sql(index))
        end

        def drop_table(index)
          execute(drop_table_sql(index))
        end

        def create_table_sql(index)
          columns = []

          index.fields.each do |field|
            next if field.sql?

            columns << "#{field.name} #{MANTICORE_TYPE_MAP[field.manticore_type] || "text"}"
          end

          index.attributes.each do |attr|
            next if attr.sql?

            columns << "#{attr.name} #{MANTICORE_TYPE_MAP[attr.manticore_type] || "string"}"
          end

          sql = "CREATE TABLE IF NOT EXISTS #{index.table_name} (#{columns.join(", ")})"

          if index.properties.any?
            options = index.properties.map { |k, v| "#{k} = '#{v}'" }.join(" ")
            sql += " #{options}"
          end

          sql
        end

        def drop_table_sql(index)
          "DROP TABLE IF EXISTS #{index.table_name}"
        end

        private

        def execute(sql)
          client = ManticoreClient::Client::UtilsApi.new
          sql_encoded = URI.encode_www_form_component(sql)
          response = client.sql("query=#{sql_encoded}", query_params: { mode: "raw" }).first
          raise "SQL failed: #{sql}\n#{response[:error]}" unless response[:error].empty?

          response[:data]
        end
      end
    end
  end
end
