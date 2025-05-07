# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SearchApi" do
  let(:table_name) { "#{TABLE_PREFIX}movies" }
  let(:percolate_table_name) { "#{TABLE_PREFIX}pq" }
  let(:api_instance) { Manticore::Client::SearchApi.new }
  let(:index_api) { Manticore::Client::IndexApi.new }

  before do
    # Create a simple table for testing
    ManticoreSqlHelper.query(<<~SQL)
      CREATE TABLE #{table_name}(title text, rating float) min_infix_len = '3'
    SQL
    # Insert test data
    ManticoreSqlHelper.query(<<~SQL)
      INSERT INTO #{table_name} (id, title, rating) VALUES
        (1, 'Hello world', 9.5), (2, 'Helium', 7.1), (3, 'Other', 5.0)
    SQL
  end

  after do
    ManticoreSqlHelper.drop_table(table_name)
  end

  describe "#autocomplete" do
    it "returns suggestions for prefix" do
      request = Manticore::Client::AutocompleteRequest.new(table: table_name, query: "Hel")
      result = api_instance.autocomplete(request)
      suggestions = result.first[:data].map { |row| row[:query] }
      expect(suggestions).to include("hello", "helium")
    end
  end

  describe "#search" do
    it "returns matching documents" do
      request = Manticore::Client::SearchRequest.new(table: table_name, query: { match: { title: "Hello" } })
      result = api_instance.search(request)
      expect(result.hits.total).to eq(1)
      expect(result.hits.hits.first._source[:title]).to eq("Hello world")
    end
  end

  describe "#percolate" do
    before do
      # Create a percolate table with explicit schema following the docs
      ManticoreSqlHelper.query(<<~SQL)
        CREATE TABLE #{percolate_table_name}(title text, rating float) type='pq'
      SQL

      # Insert queries in the format shown in the official docs
      ManticoreSqlHelper.query(<<~SQL)
        INSERT INTO #{percolate_table_name}(id, query, filters) VALUES
          (1, '@title hello', ''),
          (2, '@title world', ''),
          (3, '@title high', 'rating > 8.0')
      SQL
    end

    after do
      ManticoreSqlHelper.drop_table(percolate_table_name)
    end

    it "matches document against stored queries" do
      # Create a document to test against the stored queries
      # Include 'high' in the title to match query 3 and rating > 8.0 to match the filter
      document = { title: "Hello world high", rating: 9.0 }

      # Create a percolate request following the docs
      request = Manticore::Client::PercolateRequest.new(
        query: {
          percolate: {
            document: document
          }
        }
      )

      # Perform the percolate search
      result = api_instance.percolate(percolate_table_name, request)

      # Verify the results
      expect(result.hits.total).to be >= 2 # Should match queries 1, 2, and 3

      # Extract the matched query IDs
      query_ids = result.hits.hits.map { |hit| hit._id.to_i }

      # Verify specific matches
      expect(query_ids).to include(1)  # '@title hello' query
      expect(query_ids).to include(2)  # '@title world' query
      expect(query_ids).to include(3)  # '@title high' with 'rating > 8.0' filter
    end
  end
end
