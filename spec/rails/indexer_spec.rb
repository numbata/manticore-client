# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreRails::Indexer do
  let(:model_class) do
    Struct.new(:table_name).new("episodes")
  end

  let(:index) { ManticoreRails::Index.new(model_class) }
  let(:indexer) { described_class.new(index) }

  before do
    ManticoreRails.configuration.index_prefix = nil

    index.add_field(:name)
    index.add_field(:description)
    index.add_attribute(:id, type: :integer)
    index.add_attribute(:beginning, type: :datetime)
    index.add_attribute(:channel_id, type: :integer)
  end

  describe "#serialize" do
    it "serializes simple fields" do
      record = double("record", id: 1, name: "Test Episode", description: "A description",
                                beginning: Time.new(2024, 1, 15, 12, 0, 0), channel_id: 42)

      doc = indexer.serialize(record)

      expect(doc["id"]).to eq(1)
      expect(doc["name"]).to eq("Test Episode")
      expect(doc["description"]).to eq("A description")
    end

    it "coerces Time attributes to integers" do
      time = Time.new(2024, 1, 15, 12, 0, 0)
      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: time, channel_id: 42)

      doc = indexer.serialize(record)
      expect(doc["beginning"]).to eq(time.to_i)
    end

    it "coerces boolean true to 1 and false to 0" do
      index.add_attribute(:active, type: :boolean)
      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: Time.now, channel_id: 42, active: true)

      doc = indexer.serialize(record)
      expect(doc["active"]).to eq(1)
    end

    it "coerces nil numeric attributes to 0" do
      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: nil, channel_id: nil)

      doc = indexer.serialize(record)
      expect(doc["beginning"]).to eq(0)
      expect(doc["channel_id"]).to eq(0)
    end

    it "skips SQL fields (returns nil, compacted out)" do
      index.add_field("(SELECT GROUP_CONCAT(...) FROM ...)", as: :custom_field)
      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: Time.now, channel_id: 1)

      doc = indexer.serialize(record)
      expect(doc).not_to have_key("custom_field")
    end

    it "skips SQL attributes (not stored in schema)" do
      index.add_attribute("(SELECT COUNT(*) FROM tags)", as: :tag_count, type: :integer)
      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: Time.now, channel_id: 1)

      doc = indexer.serialize(record)
      expect(doc).not_to have_key("tag_count")
    end

    it "extracts association field values" do
      index.add_field("tags.name", as: :tags_name)

      tag1 = double("tag", name: "News")
      tag2 = double("tag", name: "Sports")
      tags = [tag1, tag2]

      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: Time.now, channel_id: 1, tags: tags)

      doc = indexer.serialize(record)
      expect(doc["tags_name"]).to eq("News Sports")
    end

    it "raises on deeply nested circular associations" do
      # Build a chain deeper than MAX_ASSOCIATION_DEPTH
      parts = (1..12).map { |i| "assoc#{i}" }
      deep_path = (parts + ["name"]).join(".")
      index.add_field(deep_path, as: :deep_field)

      root = double("root", id: 1, name: "Test", description: "Desc",
                            beginning: Time.now, channel_id: 1)

      current = root
      parts.each_with_index do |assoc, i|
        child = double("child#{i}")
        allow(current).to receive(assoc.to_sym).and_return(child)
        current = child
      end
      allow(current).to receive(:name).and_return("leaf")

      expect { indexer.serialize(root) }.to raise_error(RuntimeError, /Circular association detected/)
    end

    it "uses manticore_serialize override when available" do
      custom_doc = { "id" => 1, "name" => "Custom" }
      record = double("record", manticore_serialize: custom_doc)
      allow(record).to receive(:respond_to?).with(:manticore_serialize).and_return(true)

      doc = indexer.serialize(record)
      expect(doc).to eq(custom_doc)
    end

    it "handles symbol-keyed docs from custom serializers in bulk_replace" do
      index_api = instance_double(ManticoreClient::Client::IndexApi)
      allow(ManticoreClient::Client::IndexApi).to receive(:new).and_return(index_api)
      allow(index_api).to receive(:bulk)

      docs = [{ id: 5, title: "Test" }]
      indexer.send(:bulk_replace, docs)

      expect(index_api).to have_received(:bulk).once do |ndjson|
        parsed = JSON.parse(ndjson)
        expect(parsed["replace"]["id"]).to eq(5)
        expect(parsed["replace"]["doc"]).to eq({ "title" => "Test" })
      end
    end
  end

  describe "#check_bulk_response" do
    it "reports errors via on_error callback" do
      errors = []
      ManticoreRails.configuration.on_error = ->(msg, err) { errors << [msg, err.message] }

      response = double("response", errors: true, error: "some docs failed",
                                    items: [{ "replace" => { "id" => 1, "error" => "bad" } }])

      indexer.send(:check_bulk_response, response)

      expect(errors.size).to eq(1)
      expect(errors.first.first).to eq("some docs failed")
    ensure
      ManticoreRails.configuration.on_error = nil
    end

    it "does nothing when no errors" do
      response = double("response", errors: false)
      expect { indexer.send(:check_bulk_response, response) }.not_to raise_error
    end
  end

  describe "#delete_records" do
    it "sends a single bulk NDJSON request" do
      index_api = instance_double(ManticoreClient::Client::IndexApi)
      allow(ManticoreClient::Client::IndexApi).to receive(:new).and_return(index_api)
      allow(index_api).to receive(:bulk)

      indexer.delete_records([1, 2, 3])

      expect(index_api).to have_received(:bulk).once do |ndjson|
        lines = ndjson.split("\n").map { |l| JSON.parse(l) }
        expect(lines.size).to eq(3)
        expect(lines.map { |l| l["delete"]["id"] }).to eq([1, 2, 3])
        expect(lines.all? { |l| l["delete"]["index"] == "episodes" }).to be(true)
      end
    end

    it "does nothing for empty ids" do
      index_api = instance_double(ManticoreClient::Client::IndexApi)
      allow(ManticoreClient::Client::IndexApi).to receive(:new).and_return(index_api)

      indexer.delete_records([])

      expect(ManticoreClient::Client::IndexApi).not_to have_received(:new)
    end
  end

  describe "#index_records" do
    it "loads records and bulk upserts" do
      record = double("record", id: 1, name: "Test", description: "Desc",
                                beginning: Time.now, channel_id: 1)

      scope = [record]
      allow(index).to receive(:model_class).and_return(double("ar_class", table_name: "episodes", where: scope))

      index_api = instance_double(ManticoreClient::Client::IndexApi)
      allow(ManticoreClient::Client::IndexApi).to receive(:new).and_return(index_api)
      allow(index_api).to receive(:bulk)

      indexer.index_records([1])

      expect(index_api).to have_received(:bulk) do |ndjson|
        parsed = JSON.parse(ndjson)
        expect(parsed["replace"]["index"]).to eq("episodes")
        expect(parsed["replace"]["id"]).to eq(1)
      end
    end
  end
end
