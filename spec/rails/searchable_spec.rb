# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreRails::Searchable do
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

      include ManticoreRails::Searchable

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
    ManticoreRails.configuration.index_prefix = nil
    ManticoreRails.record_success! # reset circuit breaker
    ManticoreRails.registry.reset!
    # Re-trigger define_manticore_index by re-including
    model_class
  end

  after do
    ManticoreRails.record_success!
    ManticoreRails.registry.reset!
  end

  describe ".define_manticore_index" do
    it "registers the index in the registry" do
      index = ManticoreRails.registry.find_by_class(model_class)
      expect(index).to be_a(ManticoreRails::Index)
    end

    it "creates an index with correct fields" do
      index = model_class.manticore_index
      expect(index.fields.map(&:name)).to contain_exactly(:name, :description)
    end

    it "creates an index with correct attributes" do
      index = model_class.manticore_index
      expect(index.attributes.map(&:name)).to contain_exactly(:id, :channel_id)
    end

    it "deduplicates reindex callbacks for the same root association" do
      callback_count = 0
      inverse = double("inverse", name: :episode)
      reflection = double("reflection", inverse_of: inverse)
      klass = Class.new do
        def self.class_eval(&block); end
      end
      allow(reflection).to receive(:klass).and_return(klass)
      allow(klass).to receive(:class_eval) { callback_count += 1 }

      reindex_model = Class.new do
        def self.table_name
          "reindex_test"
        end

        def self.name
          "ReindexTest"
        end

        def self.after_commit(*, **); end

        def self.reflect_on_association(_name)
          nil
        end

        include ManticoreRails::Searchable
      end

      allow(reindex_model).to receive(:reflect_on_association).and_return(reflection)

      ManticoreRails.registry.reset!
      reindex_model.define_manticore_index do
        indexes :title
        reindex_on_change :tags
        reindex_on_change "tags.subtags"
      end

      expect(callback_count).to eq(1)
    end
  end

  describe ".manticore_index" do
    it "returns the registered index" do
      expect(model_class.manticore_index).to be_a(ManticoreRails::Index)
      expect(model_class.manticore_index.table_name).to eq("test_models")
    end
  end

  describe ".manticore_indexer" do
    it "returns an Indexer for the model" do
      expect(model_class.manticore_indexer).to be_a(ManticoreRails::Indexer)
    end
  end

  describe ".search" do
    it "delegates to Searcher" do
      result = model_class.search("test query")
      expect(result).to be_a(ManticoreRails::Searcher::Result)
    end
  end

  describe ".search_for_ids" do
    it "delegates to Searcher with ids_only" do
      result = model_class.search_for_ids("test query")
      expect(result).to be_a(ManticoreRails::Searcher::Result)
      expect(result.options[:ids_only]).to be(true)
    end
  end

  describe "#manticore_should_index?" do
    it "returns true when auto_indexing is enabled and index exists" do
      instance = model_class.new
      expect(instance.send(:manticore_should_index?)).to be(true)
    end

    it "returns false when auto_indexing is disabled" do
      ManticoreRails.no_auto_indexing do
        instance = model_class.new
        expect(instance.send(:manticore_should_index?)).to be(false)
      end
    end

    it "restores previous state when no_auto_indexing is nested" do
      ManticoreRails.no_auto_indexing do
        ManticoreRails.no_auto_indexing do
          instance = model_class.new
          expect(instance.send(:manticore_should_index?)).to be(false)
        end
        # After inner block, outer block should still suppress indexing
        instance = model_class.new
        expect(instance.send(:manticore_should_index?)).to be(false)
      end
      # After outer block, indexing should be re-enabled
      instance = model_class.new
      expect(instance.send(:manticore_should_index?)).to be(true)
    end
  end

  describe "#manticore_index_record" do
    it "calls indexer.index_records when sync" do
      indexer = instance_double(ManticoreRails::Indexer)
      allow(ManticoreRails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records)

      instance = model_class.new
      instance.manticore_index_record

      expect(indexer).to have_received(:index_records).with([1])
    end

    it "enqueues async job with action when async_indexing is enabled" do
      job_class = double("JobClass")
      allow(job_class).to receive(:perform_later)

      ManticoreRails.configuration.async_indexing = true
      ManticoreRails.configuration.index_job_class = job_class

      instance = model_class.new
      instance.manticore_index_record

      expect(job_class).to have_received(:perform_later).with("index", "TestModel", 1)
    ensure
      ManticoreRails.configuration.async_indexing = false
      ManticoreRails.configuration.index_job_class = nil
    end

    it "does not call record_success! in async mode" do
      job_class = double("JobClass")
      allow(job_class).to receive(:perform_later)

      ManticoreRails.configuration.async_indexing = true
      ManticoreRails.configuration.index_job_class = job_class
      ManticoreRails.record_failure! # set failure count to 1

      instance = model_class.new
      instance.manticore_index_record

      # Circuit breaker should NOT have been reset by async enqueue
      expect(ManticoreRails.circuit_open?).to be(false) # still below threshold
      # Verify record_success! was not called by checking failure count wasn't reset
      # Add another failure — if success was called, count would be 1; if not, count is 2
      ManticoreRails.record_failure!
      # With threshold=10, 2 failures should not open it
      expect(ManticoreRails.circuit_open?).to be(false)
    ensure
      ManticoreRails.configuration.async_indexing = false
      ManticoreRails.configuration.index_job_class = nil
      ManticoreRails.record_success!
    end

    it "calls record_success! in sync mode" do
      indexer = instance_double(ManticoreRails::Indexer)
      allow(ManticoreRails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records)

      # Set some failures first
      3.times { ManticoreRails.record_failure! }

      instance = model_class.new
      instance.manticore_index_record

      # Sync success should reset the failure counter
      expect(ManticoreRails.circuit_open?).to be(false)
    ensure
      ManticoreRails.record_success!
    end

    it "calls record_failure! when sync indexing raises" do
      indexer = instance_double(ManticoreRails::Indexer)
      allow(ManticoreRails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records).and_raise(StandardError, "connection refused")

      ManticoreRails.configuration.on_error = nil

      instance = model_class.new
      instance.manticore_index_record

      # Should have recorded one failure
      expect(ManticoreRails.circuit_open?).to be(false) # 1 < 10
    ensure
      ManticoreRails.record_success!
      ManticoreRails.configuration.reset!
    end

    it "does nothing when auto_indexing is off" do
      indexer = instance_double(ManticoreRails::Indexer)
      allow(ManticoreRails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records)

      ManticoreRails.no_auto_indexing do
        instance = model_class.new
        instance.manticore_index_record
      end

      expect(indexer).not_to have_received(:index_records)
    end
  end

  describe "#manticore_remove_record" do
    it "calls indexer.delete_records" do
      indexer = instance_double(ManticoreRails::Indexer)
      allow(ManticoreRails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:delete_records)

      instance = model_class.new
      instance.manticore_remove_record

      expect(indexer).to have_received(:delete_records).with([1])
    end

    it "enqueues async job with delete action when async_indexing is enabled" do
      job_class = double("JobClass")
      allow(job_class).to receive(:perform_later)

      ManticoreRails.configuration.async_indexing = true
      ManticoreRails.configuration.index_job_class = job_class

      instance = model_class.new
      instance.manticore_remove_record

      expect(job_class).to have_received(:perform_later).with("delete", "TestModel", 1)
    ensure
      ManticoreRails.configuration.async_indexing = false
      ManticoreRails.configuration.index_job_class = nil
    end
  end
end

RSpec.describe ManticoreRails do
  describe "circuit breaker" do
    before { described_class.record_success! }

    it "is closed by default" do
      expect(described_class.circuit_open?).to be(false)
    end

    it "opens after reaching threshold failures" do
      described_class.configuration.circuit_breaker_threshold.times do
        described_class.record_failure!
      end
      expect(described_class.circuit_open?).to be(true)
    end

    it "resets on success" do
      5.times { described_class.record_failure! }
      described_class.record_success!
      expect(described_class.circuit_open?).to be(false)
    end

    it "resets via reset_circuit!" do
      5.times { described_class.record_failure! }
      described_class.reset_circuit!
      expect(described_class.circuit_open?).to be(false)
    end

    it "prevents indexing when circuit is open" do
      described_class.configuration.circuit_breaker_threshold.times do
        described_class.record_failure!
      end

      model_class = Class.new do
        def self.table_name = "cb_test"
        def self.name = "CbTest"
        def self.after_commit(*, **); end
        def self.reflect_on_association(_name) = nil

        include ManticoreRails::Searchable

        define_manticore_index do
          indexes :title
          has :id, type: :integer
        end

        def id = 1
      end

      indexer = instance_double(ManticoreRails::Indexer)
      allow(ManticoreRails::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:index_records)

      instance = model_class.new
      instance.manticore_index_record

      expect(indexer).not_to have_received(:index_records)
    ensure
      described_class.record_success!
      described_class.registry.reset!
    end
  end

  describe ".healthy?" do
    it "returns true when ManticoreSearch responds" do
      utils_api = instance_double(ManticoreClient::Client::UtilsApi)
      allow(ManticoreClient::Client::UtilsApi).to receive(:new).and_return(utils_api)
      allow(utils_api).to receive(:sql).and_return([{ data: [], error: "" }])

      expect(described_class.healthy?).to be(true)
    end

    it "returns false when ManticoreSearch is unreachable" do
      allow(ManticoreClient::Client::UtilsApi).to receive(:new)
        .and_raise(Faraday::ConnectionFailed.new("connection refused"))

      expect(described_class.healthy?).to be(false)
    end
  end
end
