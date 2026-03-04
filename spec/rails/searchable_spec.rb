# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreClient::Rails::Searchable do
  # Create a mock model class that includes Searchable
  let(:model_class) do
    klass = Class.new do
      def self.table_name
        "test_models"
      end

      def self.name
        "TestModel"
      end

      def self.after_commit(*, **)
        # no-op in tests
      end

      def self.reflect_on_association(_name)
        nil
      end

      include ManticoreClient::Rails::Searchable

      define_manticore_index do
        indexes :name
        indexes :description
        has :id, type: :integer
        has :channel_id, type: :integer
      end

      def id
        1
      end
    end

    klass
  end

  before do
    ManticoreClient::Rails.configuration.index_prefix = nil
    ManticoreClient::Rails.registry.reset!
    # Re-trigger define_manticore_index by re-including
    model_class
  end

  after do
    ManticoreClient::Rails.registry.reset!
  end

  describe ".define_manticore_index" do
    it "registers the index in the registry" do
      index = ManticoreClient::Rails.registry.find_by_class(model_class)
      expect(index).to be_a(ManticoreClient::Rails::Index)
    end

    it "creates an index with correct fields" do
      index = model_class.manticore_index
      expect(index.fields.map(&:name)).to contain_exactly(:name, :description)
    end

    it "creates an index with correct attributes" do
      index = model_class.manticore_index
      expect(index.attributes.map(&:name)).to contain_exactly(:id, :channel_id)
    end
  end

  describe ".manticore_index" do
    it "returns the registered index" do
      expect(model_class.manticore_index).to be_a(ManticoreClient::Rails::Index)
      expect(model_class.manticore_index.table_name).to eq("test_models")
    end
  end

  describe ".manticore_indexer" do
    it "returns an Indexer for the model" do
      expect(model_class.manticore_indexer).to be_a(ManticoreClient::Rails::Indexer)
    end
  end

  describe ".search" do
    it "delegates to Searcher" do
      result = model_class.search("test query")
      expect(result).to be_a(ManticoreClient::Rails::Result)
    end
  end

  describe ".search_for_ids" do
    it "delegates to Searcher with ids_only" do
      result = model_class.search_for_ids("test query")
      expect(result).to be_a(ManticoreClient::Rails::Result)
      expect(result.options[:ids_only]).to be(true)
    end
  end

  describe "#manticore_should_index?" do
    it "returns true when auto_indexing is enabled and index exists" do
      instance = model_class.new
      expect(instance.manticore_should_index?).to be(true)
    end

    it "returns false when auto_indexing is disabled" do
      ManticoreClient::Rails.no_auto_indexing do
        instance = model_class.new
        expect(instance.manticore_should_index?).to be(false)
      end
    end
  end

  describe "#manticore_index_record" do
    it "calls indexer.index_records when sync" do
      indexer = instance_double(ManticoreClient::Rails::Indexer)
      allow(ManticoreClient::Rails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records)

      instance = model_class.new
      instance.manticore_index_record

      expect(indexer).to have_received(:index_records).with([1])
    end

    it "does nothing when auto_indexing is off" do
      indexer = instance_double(ManticoreClient::Rails::Indexer)
      allow(ManticoreClient::Rails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records)

      ManticoreClient::Rails.no_auto_indexing do
        instance = model_class.new
        instance.manticore_index_record
      end

      expect(indexer).not_to have_received(:index_records)
    end
  end

  describe "#manticore_remove_record" do
    it "calls indexer.delete_records" do
      indexer = instance_double(ManticoreClient::Rails::Indexer)
      allow(ManticoreClient::Rails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:delete_records)

      instance = model_class.new
      instance.manticore_remove_record

      expect(indexer).to have_received(:delete_records).with([1])
    end
  end
end
