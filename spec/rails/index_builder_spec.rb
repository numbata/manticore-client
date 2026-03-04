# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreClient::Rails::AssociationProxy do
  describe "simple association" do
    subject(:proxy) { described_class.new(:tags) }

    it "converts to string" do
      expect(proxy.to_s).to eq("tags")
    end

    it "chains method calls with dot notation" do
      expect(proxy.name.to_s).to eq("tags.name")
    end

    it "supports nested chains" do
      expect(proxy.dvags.name.to_s).to eq("tags.dvags.name")
    end

    it "supports to_str for implicit conversion" do
      expect(proxy.to_str).to eq("tags")
    end
  end

  describe "method call with argument" do
    subject(:proxy) { described_class.new(:transcript) }

    it "returns a string with parenthesized argument" do
      result = proxy.send(:approved_text)
      # transcript(:approved_text) style - but via method call on proxy
      # This tests the proxy.method(arg) path
    end
  end
end

RSpec.describe ManticoreClient::Rails::IndexBuilder do
  let(:model_class) do
    Struct.new(:table_name).new("episodes")
  end

  let(:configuration) { ManticoreClient::Rails::Configuration.new }

  before do
    allow(ManticoreClient::Rails).to receive(:configuration).and_return(configuration)
  end

  describe "simple field indexing" do
    subject(:builder) do
      described_class.new do
        indexes :name
        indexes :description
      end
    end

    it "collects field definitions" do
      index = builder.build(model_class)
      expect(index.fields.map(&:name)).to eq(%i[name description])
    end
  end

  describe "association field indexing" do
    subject(:builder) do
      described_class.new do
        indexes tags.name, as: :tags_name
      end
    end

    it "creates a field with association column" do
      index = builder.build(model_class)
      field = index.fields.first
      expect(field.name).to eq(:tags_name)
      expect(field.association?).to be(true)
      expect(field.association_name).to eq(:tags)
      expect(field.column_name).to eq(:name)
    end
  end

  describe "SQL string field" do
    subject(:builder) do
      described_class.new do
        indexes "(SELECT GROUP_CONCAT(name) FROM anchors WHERE anchors.episode_id = episodes.id)", as: :anchors_title
      end
    end

    it "creates a SQL field" do
      index = builder.build(model_class)
      field = index.fields.first
      expect(field.name).to eq(:anchors_title)
      expect(field.sql?).to be(true)
    end
  end

  describe "method call with argument (transcript pattern)" do
    subject(:builder) do
      described_class.new do
        indexes transcript(:approved_text), as: :transcript_approved_text
      end
    end

    it "creates a field from method call with argument" do
      index = builder.build(model_class)
      field = index.fields.first
      expect(field.name).to eq(:transcript_approved_text)
      expect(field.column).to eq("transcript(approved_text)")
    end
  end

  describe "attributes with has" do
    subject(:builder) do
      described_class.new do
        has :id, type: :integer
        has :beginning, type: :datetime, sortable: true
      end
    end

    it "collects attribute definitions" do
      index = builder.build(model_class)
      expect(index.attributes.size).to eq(2)

      id_attr = index.attributes.first
      expect(id_attr.name).to eq(:id)
      expect(id_attr.type).to eq(:integer)
      expect(id_attr.manticore_type).to eq(:bigint)

      beginning_attr = index.attributes.last
      expect(beginning_attr.name).to eq(:beginning)
      expect(beginning_attr.type).to eq(:datetime)
      expect(beginning_attr.sortable?).to be(true)
    end
  end

  describe "association attribute with method call" do
    subject(:builder) do
      described_class.new do
        has tags(:company_id), as: :company_ids, type: :integer
      end
    end

    it "creates an attribute from method call with argument" do
      index = builder.build(model_class)
      attr = index.attributes.first
      expect(attr.name).to eq(:company_ids)
      expect(attr.column).to eq("tags(company_id)")
      expect(attr.type).to eq(:integer)
    end
  end

  describe "reindex_on_change" do
    subject(:builder) do
      described_class.new do
        reindex_on_change :anchors
        reindex_on_change anchors.dvags
      end
    end

    it "collects reindex associations" do
      index = builder.build(model_class)
      expect(index.reindex_associations).to eq(%w[anchors anchors.dvags])
    end
  end

  describe "set_property" do
    subject(:builder) do
      described_class.new do
        set_property min_prefix_len: 2
        set_property morphology: "stem_en"
      end
    end

    it "merges properties into the index" do
      index = builder.build(model_class)
      expect(index.properties).to eq(min_prefix_len: 2, morphology: "stem_en")
    end
  end

  describe "full legacy Episode pattern" do
    subject(:builder) do
      described_class.new do
        indexes :name
        indexes :description
        indexes tags.name, as: :tags_name
        indexes "(SELECT GROUP_CONCAT(title) FROM anchors WHERE anchors.episode_id = episodes.id)", as: :anchors_title
        indexes transcript(:approved_text), as: :transcript_approved_text

        has :id, type: :integer
        has :beginning, type: :datetime, sortable: true
        has :channel_id, type: :integer
        has tags(:company_id), as: :company_ids, type: :integer

        reindex_on_change :anchors
        reindex_on_change anchors.dvags

        set_property min_prefix_len: 2
      end
    end

    it "builds a complete index" do
      index = builder.build(model_class)

      expect(index.fields.size).to eq(5)
      expect(index.attributes.size).to eq(4)
      expect(index.reindex_associations).to eq(%w[anchors anchors.dvags])
      expect(index.properties).to eq(min_prefix_len: 2)
    end

    it "correctly categorizes field types" do
      index = builder.build(model_class)

      names = index.fields.map(&:name)
      expect(names).to eq(%i[name description tags_name anchors_title transcript_approved_text])

      sql_fields = index.fields.select(&:sql?)
      expect(sql_fields.size).to eq(1)
      expect(sql_fields.first.name).to eq(:anchors_title)

      assoc_fields = index.fields.select(&:association?)
      expect(assoc_fields.size).to eq(1)
      expect(assoc_fields.first.name).to eq(:tags_name)
    end
  end
end
