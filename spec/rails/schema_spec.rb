# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Manticore::Rails::Schema do
  let(:model_class) { Struct.new(:table_name).new("episodes") }
  let(:index) { Manticore::Rails::Index.new(model_class) }

  before do
    Manticore::Rails.configuration.index_prefix = nil

    index.add_field(:name)
    index.add_field(:description)
    index.add_field("tags.name", as: :tags_name)
    index.add_attribute(:id, type: :integer)
    index.add_attribute(:beginning, type: :datetime, sortable: true)
    index.add_attribute(:channel_id, type: :integer)
  end

  describe ".create_table_sql" do
    it "generates CREATE TABLE with fields and attributes" do
      sql = described_class.create_table_sql(index)

      expect(sql).to start_with("CREATE TABLE IF NOT EXISTS episodes")
      expect(sql).to include("name text")
      expect(sql).to include("description text")
      expect(sql).to include("tags_name text")
      expect(sql).to include("id bigint")
      expect(sql).to include("beginning timestamp")
      expect(sql).to include("channel_id bigint")
    end

    it "excludes SQL fields from DDL" do
      index.add_field("(SELECT GROUP_CONCAT(...) FROM ...)", as: :anchors_title)
      sql = described_class.create_table_sql(index)

      expect(sql).not_to include("anchors_title")
    end

    it "excludes SQL attributes from DDL" do
      index.add_attribute("CAST(substring_index(ancestry, '/', 1) AS unsigned)", as: :root_id, type: :integer)
      sql = described_class.create_table_sql(index)

      expect(sql).not_to include("root_id")
    end

    it "includes properties as table options" do
      index.set_property(min_prefix_len: 2)
      index.set_property(enable_star: true)
      sql = described_class.create_table_sql(index)

      expect(sql).to include("min_prefix_len = '2'")
      expect(sql).to include("enable_star = 'true'")
    end

    it "maps all types correctly" do
      idx = Manticore::Rails::Index.new(model_class)
      idx.add_field(:title)
      idx.add_attribute(:flag, type: :boolean)
      idx.add_attribute(:score, type: :float)
      idx.add_attribute(:label, type: :string)

      sql = described_class.create_table_sql(idx)

      expect(sql).to include("title text")
      expect(sql).to include("flag bool")
      expect(sql).to include("score float")
      expect(sql).to include("label string")
    end
  end

  describe ".drop_table_sql" do
    it "generates DROP TABLE statement" do
      sql = described_class.drop_table_sql(index)
      expect(sql).to eq("DROP TABLE IF EXISTS episodes")
    end
  end

  describe ".create_table" do
    it "executes DDL via UtilsApi" do
      utils_api = instance_double(Manticore::Client::UtilsApi)
      allow(Manticore::Client::UtilsApi).to receive(:new).and_return(utils_api)
      allow(utils_api).to receive(:sql).and_return([{ error: "", data: [] }])

      described_class.create_table(index)

      expect(utils_api).to have_received(:sql) do |body, **opts|
        expect(body).to start_with("query=")
        expect(opts[:query_params]).to eq({ mode: "raw" })
      end
    end
  end

  describe ".drop_table" do
    it "executes DROP via UtilsApi" do
      utils_api = instance_double(Manticore::Client::UtilsApi)
      allow(Manticore::Client::UtilsApi).to receive(:new).and_return(utils_api)
      allow(utils_api).to receive(:sql).and_return([{ error: "", data: [] }])

      described_class.drop_table(index)

      expect(utils_api).to have_received(:sql) do |body, **opts|
        decoded = URI.decode_www_form_component(body.sub("query=", ""))
        expect(decoded).to eq("DROP TABLE IF EXISTS episodes")
      end
    end
  end
end
