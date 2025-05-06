module ManticoreSqlHelper
  QueryError = Class.new(StandardError) do
    attr_reader :sql, :error

    def initialize(error, sql)
      @sql = sql
      @error = error
      super("SQL query failed: #{sql}\n#{error}")
    end
  end

  def self.client
    @client ||= Manticore::Client::UtilsApi.new
  end

  def self.query(sql)
    response = client.sql("query=#{sql}", query_params: {mode: "raw"}).first
    raise QueryError.new(response[:error], sql) unless response[:error].empty?

    response[:data]
  end

  def self.tables(prefix: nil)
      res = query("SHOW TABLES")
      tables = res.map { |row| row[:Table] }
      prefix ? tables.select { |t| t.start_with?(prefix) } : tables
  end

  def self.drop_table(name)
    query("DROP TABLE #{name}")
  end
end
