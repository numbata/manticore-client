# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UtilsApi' do
  let(:table_name) { "#{TABLE_PREFIX}utils_test" }
  let(:api_instance) { Manticore::Client::UtilsApi.new }

  before do
    # Create a test table
    sql = "CREATE TABLE #{table_name} (title text, rating float)"
    api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})
  end

  after do
    # Drop the test table
    begin
      sql = "DROP TABLE #{table_name}"
      api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})
    rescue => e
      puts "Warning: Could not drop table #{table_name}: #{e.message}"
    end
  end

  describe '#sql' do
    it 'creates an instance of UtilsApi' do
      expect(api_instance).to be_instance_of(Manticore::Client::UtilsApi)
    end

    it 'executes INSERT statement' do
      # Insert test data
      sql = "INSERT INTO #{table_name} (id, title, rating) VALUES (1, 'Test Movie', 8.5)"
      result = api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})

      # Verify the result
      expect(result).to be_an(Array)
      expect(result.first[:total]).to eq(1)  # 1 row affected
      expect(result.first[:error]).to be_empty
    end

    it 'executes SELECT statement' do
      # Insert test data
      sql = "INSERT INTO #{table_name} (id, title, rating) VALUES (1, 'Test Movie', 8.5)"
      api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})

      # Query the data
      sql = "SELECT * FROM #{table_name}"
      result = api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})

      # Verify the result
      expect(result).to be_an(Array)
      expect(result.first[:data]).to be_an(Array)
      expect(result.first[:data].size).to eq(1)
      expect(result.first[:data].first[:title]).to eq('Test Movie')
      expect(result.first[:data].first[:rating]).to eq(8.5)
    end

    it 'executes SHOW TABLES statement' do
      # Query tables
      sql = "SHOW TABLES"
      result = api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})

      # Verify the result
      expect(result).to be_an(Array)
      expect(result.first[:columns]).to be_an(Array)
      expect(result.first[:data]).to be_an(Array)
      
      # The test table should be in the list
      table_names = result.first[:data].map { |row| row[:Table] }
      expect(table_names).to include(table_name)
    end

    it 'handles errors gracefully' do
      # Execute an invalid SQL statement
      sql = "SELECT * FROM non_existent_table"
      
      # The API should raise an exception
      expect {
        api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})
      }.to raise_error(Manticore::Client::ApiError) do |error|
        expect(error.response_body).to include('error')
      end
    end

    it 'supports raw_response parameter' do
      # Insert test data
      sql = "INSERT INTO #{table_name} (id, title, rating) VALUES (2, 'Another Movie', 7.0)"
      api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: {mode: "raw"})

      # Query with raw_response=false and mode=raw
      sql = "SELECT * FROM #{table_name} WHERE id = 2"
      result = api_instance.sql("query=#{URI.encode_www_form_component(sql)}", query_params: { raw_response: false, mode: "raw" })

      # Verify the result format is different with raw_response=false
      expect(result).to be_an(Array)
      expect(result.first[:data]).to be_an(Array)
      expect(result.first[:data].size).to eq(1)
      expect(result.first[:data].first[:title]).to eq('Another Movie')
    end
  end
end
