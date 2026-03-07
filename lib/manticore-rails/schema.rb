# frozen_string_literal: true

module ManticoreRails
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
        columns = (index.fields + index.attributes).map do |col|
          next if col.sql? && !col.options[:as]

          "#{col.name} #{MANTICORE_TYPE_MAP[col.manticore_type] || 'string'}"
        end.compact

        sql = "CREATE TABLE IF NOT EXISTS #{index.table_name} (#{columns.join(', ')})"

        if index.properties.any?
          options = index.properties.map do |k, v|
            key = k.to_s
            raise ArgumentError, "Invalid property name: #{key}" unless key.match?(/\A[a-z_][a-z0-9_]*\z/i)

            "#{key} = '#{v.to_s.gsub("'", "''")}'"
          end.join(" ")
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
