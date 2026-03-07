# frozen_string_literal: true

module ManticoreRails
  # Generates and executes DDL statements (CREATE TABLE / DROP TABLE)
  # against ManticoreSearch via the SQL API.
  #
  # @example Create a table for an index
  #   ManticoreRails::Schema.create_table(Article.manticore_index)
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
      # Creates the ManticoreSearch table for the given index.
      # @param index [Index] the index whose table to create
      # @return [Array] the raw response data from ManticoreSearch
      def create_table(index)
        execute(create_table_sql(index))
      end

      # Drops the ManticoreSearch table for the given index.
      # @param index [Index] the index whose table to drop
      # @return [Array] the raw response data from ManticoreSearch
      def drop_table(index)
        execute(drop_table_sql(index))
      end

      # Generates a +CREATE TABLE IF NOT EXISTS+ SQL statement.
      # @param index [Index] the index definition
      # @return [String] the DDL statement
      # @raise [ArgumentError] if a property name contains invalid characters
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

      # Generates a +DROP TABLE IF EXISTS+ SQL statement.
      # @param index [Index] the index definition
      # @return [String] the DDL statement
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
