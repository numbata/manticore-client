# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IndexApi' do
  subject(:index_api) { Manticore::Client::IndexApi.new }
  let(:table_name) { "#{TABLE_PREFIX}movies" }

  before do
    ManticoreSqlHelper.query("CREATE TABLE #{table_name} (title TEXT, rating FLOAT)")
    ManticoreSqlHelper.query(<<~SQL)
      INSERT INTO #{table_name} (id, title, rating) VALUES
        (1, 'Scary movie', 9.5),
        (2, 'Horror movie', 2.1)
    SQL
  end

  after do
    ManticoreSqlHelper.drop_table(table_name)
  end

  # Sends multiple operations like inserts, updates, replaces, or deletes.
  describe "#bulk" do
    it "creates batch of documents" do
      request_body = <<~NDJSON
        { "insert": { "index": "#{table_name}", "id": 3, "doc": { "title": "New movie", "rating": 8.5 } } }
        { "delete": { "index": "#{table_name}", "id": 2 } }
      NDJSON

      result = index_api.bulk(request_body)

      expect(result.items[0][:bulk]).to include(
        table: table_name,
        created: 1,
        deleted: 1,
        result: "updated"
      )
      expect(table_name).to have_docs(
        { id: 1, title: "Scary movie", rating: 9.5 },
        { id: 3, title: "New movie", rating: 8.5 },
      )
      expect(table_name).not_to have_docs(
        { id: 2, title: "Horror movie", rating: 2.1 }
      )
    end
  end

  # Delete one or several documents.
  describe '#delete' do
    it "removes one doc from table" do
      request = Manticore::Client::DeleteDocumentRequest.new(
        table: table_name,
        id: 2
      )

      result = index_api.delete(request)

      expect(result).to be_a(Manticore::Client::DeleteResponse)
      expect(result).to have_attributes(
        table: table_name,
        result: "deleted",
      )
      expect(table_name).to have_docs(
        { id: 1, title: "Scary movie", rating: 9.5 }
      )
      expect(table_name).not_to have_docs(
        { id: 2, title: "Horror movie", rating: 2.1 }
      )
    end

    it "removes several docs from table" do
      request = Manticore::Client::DeleteDocumentRequest.new(
        table: table_name,
        id: [1, 2]
      )

      result = index_api.delete(request)

      expect(result).to be_a(Manticore::Client::DeleteResponse)
      expect(result).to have_attributes(
        table: table_name,
        result: "deleted",
      )
      expect(table_name).not_to have_docs(
        { id: 1, title: "Scary movie", rating: 9.5 },
        { id: 2, title: "Horror movie", rating: 2.1 }
      )
    end
  end

  # Insert a new document in a table.
  describe '#insert' do
    it 'inserts a new document' do
      request = Manticore::Client::InsertDocumentRequest.new(
        table: table_name,
        id: 3,
        doc: { title: "Brand new movie", rating: 7.7 }
      )

      result = index_api.insert(request)

      expect(result).to be_a(Manticore::Client::SuccessResponse)
      expect(result).to have_attributes(
        table: table_name,
        id: 3,
        created: true,
        result: "created"
      )
      expect(table_name).to have_docs(
        { id: 3, title: "Brand new movie", rating: 7.7 }
      )
    end
  end

  # Partially replaces a document in a table.
  describe '#partial_replace' do
    it 'partially updates a document' do
      request = Manticore::Client::ReplaceDocumentRequest.new(
        doc: { rating: 8.8 }
      )
      id = 1

      result = index_api.partial_replace(table_name, id, request)

      expect(result).to be_a(Manticore::Client::UpdateResponse)
      expect(result).to have_attributes(updated: 1)
      expect(table_name).to have_docs(
        { id: 1, title: "Scary movie", rating: 8.8 }
      )
    end
  end

  # Replace a document in a table (full replace)
  describe '#replace' do
    it 'fully replaces a document' do
      request = Manticore::Client::InsertDocumentRequest.new(
        table: table_name,
        id: 1,
        doc: { title: "Completely new", rating: 5.5 }
      )

      result = index_api.replace(request)

      expect(result).to be_a(Manticore::Client::SuccessResponse)
      expect(result).to have_attributes(
        table: table_name,
        id: 1,
        created: false,
        result: "updated"
      )
      expect(table_name).to have_docs(
        { id: 1, title: "Completely new", rating: 5.5 }
      )
    end
  end

  # Update a document in a table (by id).
  describe '#update' do
    it 'updates a document by id' do
      request = Manticore::Client::UpdateDocumentRequest.new(
        table: table_name,
        id: 1,
        doc: { rating: 4.2 }
      )

      result = index_api.update(request)

      expect(result).to be_a(Manticore::Client::UpdateResponse)
      expect(result).to have_attributes(
        table: table_name,
        result: "updated"
      )
      expect(table_name).to have_docs(
        { id: 1, title: "Scary movie", rating: 4.2 }
      )
    end
  end
end
