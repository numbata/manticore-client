# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreClient::Rails::Indexer do
  let(:model_class) do
    Struct.new(:table_name).new("episodes")
  end

  let(:index) { ManticoreClient::Rails::Index.new(model_class) }
  let(:indexer) { described_class.new(index) }

  before do
    ManticoreClient::Rails.configuration.index_prefix = nil

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

    it "uses manticore_serialize override when available" do
      custom_doc = { "id" => 1, "name" => "Custom" }
      record = double("record", manticore_serialize: custom_doc)
      allow(record).to receive(:respond_to?).with(:manticore_serialize).and_return(true)

      doc = indexer.serialize(record)
      expect(doc).to eq(custom_doc)
    end
  end

  describe "#delete_records" do
    it "calls IndexApi.delete for each id" do
      index_api = instance_double(ManticoreClient::Client::IndexApi)
      allow(ManticoreClient::Client::IndexApi).to receive(:new).and_return(index_api)
      allow(index_api).to receive(:delete)

      indexer.delete_records([1, 2, 3])

      expect(index_api).to have_received(:delete).exactly(3).times
    end
  end

  describe "#index_records" do
    it "loads records and bulk upserts" do
      record = double("record", id: 1, name: "Test", description: "Desc",
                       beginning: Time.now, channel_id: 1)

      relation = double("relation")
      allow(model_class).to receive(:where).and_return(relation)
      allow(relation).to receive(:includes).and_return([record])

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
