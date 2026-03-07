# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreRails::Schema do
  let(:model_class) { Struct.new(:table_name).new("episodes") }
  let(:index) { ManticoreRails::Index.new(model_class) }

  before do
    ManticoreRails.configuration.index_prefix = nil

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

    it "includes aliased SQL fields in DDL" do
      index.add_field("(SELECT GROUP_CONCAT(...) FROM ...)", as: :anchors_title)
      sql = described_class.create_table_sql(index)

      expect(sql).to include("anchors_title text")
    end

    it "includes aliased SQL attributes in DDL" do
      index.add_attribute("CAST(substring_index(ancestry, '/', 1) AS unsigned)", as: :root_id, type: :integer)
      sql = described_class.create_table_sql(index)

      expect(sql).to include("root_id bigint")
    end

    it "includes properties as table options" do
      index.set_property(min_prefix_len: 2)
      index.set_property(enable_star: true)
      sql = described_class.create_table_sql(index)

      expect(sql).to include("min_prefix_len = '2'")
      expect(sql).to include("enable_star = 'true'")
    end

    it "escapes single quotes in property values" do
      index.set_property(morphology: "lemmatize_en, lemmatize_de")
      sql = described_class.create_table_sql(index)

      expect(sql).to include("morphology = 'lemmatize_en, lemmatize_de'")
    end

    it "rejects property keys with invalid characters" do
      index.set_property("bad'; DROP TABLE" => "evil")
      expect { described_class.create_table_sql(index) }.to raise_error(ArgumentError, /Invalid property name/)
    end

    it "maps all types correctly" do
      idx = ManticoreRails::Index.new(model_class)
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
      utils_api = instance_double(ManticoreClient::Client::UtilsApi)
      allow(ManticoreClient::Client::UtilsApi).to receive(:new).and_return(utils_api)
      allow(utils_api).to receive(:sql).and_return([{ error: "", data: [] }])

      described_class.create_table(index)

      expect(utils_api).to have_received(:sql) do |body, **opts|
        expect(body).to start_with("query=")
        expect(opts[:query_params]).to eq({ mode: "raw" })
      end
    end
  end

  describe ".create_table with SQL error" do
    it "raises when ManticoreSearch returns an error" do
      utils_api = instance_double(ManticoreClient::Client::UtilsApi)
      allow(ManticoreClient::Client::UtilsApi).to receive(:new).and_return(utils_api)
      allow(utils_api).to receive(:sql).and_return([{ error: "table already exists", data: [] }])

      expect { described_class.create_table(index) }.to raise_error(RuntimeError, /SQL failed/)
    end
  end

  describe ".drop_table" do
    it "executes DROP via UtilsApi" do
      utils_api = instance_double(ManticoreClient::Client::UtilsApi)
      allow(ManticoreClient::Client::UtilsApi).to receive(:new).and_return(utils_api)
      allow(utils_api).to receive(:sql).and_return([{ error: "", data: [] }])

      described_class.drop_table(index)

      expect(utils_api).to have_received(:sql) do |body, **_opts|
        decoded = URI.decode_www_form_component(body.sub("query=", ""))
        expect(decoded).to eq("DROP TABLE IF EXISTS episodes")
      end
    end
  end
end
