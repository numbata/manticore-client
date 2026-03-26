# frozen_string_literal: true

module ManticoreRails
  class Schema
    # Maps internal column types to ManticoreSearch DDL type names.
    MANTICORE_TYPE_MAP = {
      text: "text",
      string: "string",
      bigint: "bigint",
      timestamp: "timestamp",
      bool: "bool",
      float: "float",
      json: "json"
    }.freeze

    class << self
      def create_table(index)
        execute(create_table_sql(index))
      end

      def drop_table(index)
        execute(drop_table_sql(index))
      end

      def create_table_sql(index)
        table = index.table_name
        raise ArgumentError, "Invalid table name: #{table}" unless table.match?(/\A[a-z_]\w*\z/i)

        columns = (index.fields + index.attributes).map do |col|
          next if col.sql? && !col.options[:as]

          col_name = col.name.to_s
          raise ArgumentError, "Invalid column name: #{col_name}" unless col_name.match?(/\A[a-z_]\w*\z/i)

          "#{col_name} #{MANTICORE_TYPE_MAP[col.manticore_type] || 'string'}"
        end.compact

        sql = "CREATE TABLE IF NOT EXISTS #{table} (#{columns.join(', ')})"

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
        table = index.table_name
        raise ArgumentError, "Invalid table name: #{table}" unless table.match?(/\A[a-z_]\w*\z/i)

        "DROP TABLE IF EXISTS #{table}"
      end

      private

        def execute(sql)
          client = ManticoreClient::Client::UtilsApi.new
          sql_encoded = URI.encode_www_form_component(sql)
          results = client.sql("query=#{sql_encoded}", query_params: { mode: "raw" })
          response = results&.first
          raise "SQL failed: #{sql}\nEmpty response from ManticoreSearch" unless response

          error = response[:error]
          raise "SQL failed: #{sql}\n#{error}" if error && !error.empty?

          response[:data]
        end
    end
  end
end
