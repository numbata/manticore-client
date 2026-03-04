# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Manticore::Rails::Index do
  let(:model_class) { Struct.new(:table_name).new("articles") }

  subject(:index) { described_class.new(model_class) }

  describe "initialization" do
    it "stores the model_class" do
      expect(index.model_class).to eq(model_class)
    end

    it "starts with empty fields" do
      expect(index.fields).to eq([])
    end

    it "starts with empty attributes" do
      expect(index.attributes).to eq([])
    end

    it "starts with empty properties" do
      expect(index.properties).to eq({})
    end

    it "starts with empty reindex_associations" do
      expect(index.reindex_associations).to eq([])
    end
  end

  describe "#add_field" do
    it "adds a Field to the fields list" do
      index.add_field(:title)
      expect(index.fields.size).to eq(1)
      expect(index.fields.first).to be_a(Manticore::Rails::Field)
      expect(index.fields.first.column).to eq(:title)
    end

    it "passes options to the field" do
      index.add_field(:title, as: :custom_name)
      expect(index.fields.first.name).to eq(:custom_name)
    end
  end

  describe "#add_attribute" do
    it "adds an Attribute to the attributes list" do
      index.add_attribute(:status, type: :integer)
      expect(index.attributes.size).to eq(1)
      expect(index.attributes.first).to be_a(Manticore::Rails::Attribute)
      expect(index.attributes.first.column).to eq(:status)
    end
  end

  describe "#add_reindex_association" do
    it "adds an association to the reindex list" do
      index.add_reindex_association(:comments)
      expect(index.reindex_associations).to eq([:comments])
    end
  end

  describe "#set_property" do
    it "merges properties" do
      index.set_property(morphology: "stem_en")
      index.set_property(min_word_len: 3)
      expect(index.properties).to eq(morphology: "stem_en", min_word_len: 3)
    end

    it "overwrites existing keys" do
      index.set_property(morphology: "stem_en")
      index.set_property(morphology: "stem_ru")
      expect(index.properties).to eq(morphology: "stem_ru")
    end
  end

  describe "#table_name" do
    let(:configuration) { Manticore::Rails::Configuration.new }

    before do
      allow(Manticore::Rails).to receive(:configuration).and_return(configuration)
    end

    it "delegates to configuration without prefix" do
      expect(index.table_name).to eq("articles")
    end

    it "delegates to configuration with prefix" do
      configuration.index_prefix = "prod_"
      expect(index.table_name).to eq("prod_articles")
    end
  end

  describe "#referenced_associations" do
    it "returns unique association names from fields and attributes" do
      index.add_field("tags.name")
      index.add_field("tags.slug")
      index.add_attribute("channel.id", type: :integer)
      expect(index.referenced_associations).to eq(%i[tags channel])
    end

    it "excludes non-association fields" do
      index.add_field(:title)
      index.add_field("(SELECT COUNT(*) FROM comments)", as: :comments_count)
      expect(index.referenced_associations).to eq([])
    end
  end
end

RSpec.describe Manticore::Rails::Field do
  describe "simple symbol column" do
    subject(:field) { described_class.new(:title) }

    it "returns the column as name" do
      expect(field.name).to eq(:title)
    end

    it "is not sql" do
      expect(field.sql?).to be(false)
    end

    it "is not an association" do
      expect(field.association?).to be(false)
    end

    it "is a method call" do
      expect(field.method_call?).to be(true)
    end

    it "returns nil for association_name" do
      expect(field.association_name).to be_nil
    end

    it "returns column as column_name" do
      expect(field.column_name).to eq(:title)
    end

    it "returns empty association_path" do
      expect(field.association_path).to eq([])
    end

    it "returns :text as manticore_type" do
      expect(field.manticore_type).to eq(:text)
    end
  end

  describe "with :as option" do
    subject(:field) { described_class.new(:title, as: :custom_title) }

    it "uses :as for name" do
      expect(field.name).to eq(:custom_title)
    end
  end

  describe "SQL with parentheses" do
    subject(:field) { described_class.new("(SELECT COUNT(*) FROM comments)", as: :comments_count) }

    it "is sql" do
      expect(field.sql?).to be(true)
    end

    it "is not an association" do
      expect(field.association?).to be(false)
    end

    it "is not a method call" do
      expect(field.method_call?).to be(false)
    end

    it "uses :as for column_name" do
      expect(field.column_name).to eq(:comments_count)
    end

    it "uses :as for name" do
      expect(field.name).to eq(:comments_count)
    end
  end

  describe "SQL with SELECT keyword" do
    subject(:field) { described_class.new("SELECT name FROM tags", as: :tag_names) }

    it "is sql" do
      expect(field.sql?).to be(true)
    end

    it "is not an association" do
      expect(field.association?).to be(false)
    end
  end

  describe "SQL without :as option" do
    subject(:field) { described_class.new("(SELECT 1)") }

    it "returns :unknown for column_name" do
      expect(field.column_name).to eq(:unknown)
    end
  end

  describe "association like 'tags.name'" do
    subject(:field) { described_class.new("tags.name") }

    it "is an association" do
      expect(field.association?).to be(true)
    end

    it "is not sql" do
      expect(field.sql?).to be(false)
    end

    it "is not a method call" do
      expect(field.method_call?).to be(false)
    end

    it "returns :tags for association_name" do
      expect(field.association_name).to eq(:tags)
    end

    it "returns :name for column_name" do
      expect(field.column_name).to eq(:name)
    end

    it "returns :name for name" do
      expect(field.name).to eq(:name)
    end

    it "returns the association_path" do
      expect(field.association_path).to eq(%i[tags name])
    end
  end

  describe "nested association like 'anchors.dvags'" do
    subject(:field) { described_class.new("anchors.dvags") }

    it "is an association" do
      expect(field.association?).to be(true)
    end

    it "returns :anchors for association_name" do
      expect(field.association_name).to eq(:anchors)
    end

    it "returns :dvags for column_name" do
      expect(field.column_name).to eq(:dvags)
    end

    it "returns the association_path" do
      expect(field.association_path).to eq(%i[anchors dvags])
    end
  end
end

RSpec.describe Manticore::Rails::Attribute do
  describe "type mapping" do
    it "maps integer to bigint" do
      attr = described_class.new(:count, type: :integer)
      expect(attr.manticore_type).to eq(:bigint)
    end

    it "maps datetime to timestamp" do
      attr = described_class.new(:created_at, type: :datetime)
      expect(attr.manticore_type).to eq(:timestamp)
    end

    it "maps boolean to bool" do
      attr = described_class.new(:active, type: :boolean)
      expect(attr.manticore_type).to eq(:bool)
    end

    it "maps float to float" do
      attr = described_class.new(:rating, type: :float)
      expect(attr.manticore_type).to eq(:float)
    end

    it "maps string to string" do
      attr = described_class.new(:status, type: :string)
      expect(attr.manticore_type).to eq(:string)
    end

    it "defaults unknown type to string" do
      attr = described_class.new(:data, type: :json)
      expect(attr.manticore_type).to eq(:string)
    end
  end

  describe "#type" do
    it "returns the configured type" do
      attr = described_class.new(:count, type: :integer)
      expect(attr.type).to eq(:integer)
    end

    it "defaults to :string when no type given" do
      attr = described_class.new(:status)
      expect(attr.type).to eq(:string)
    end
  end

  describe "#sortable?" do
    it "returns true when sortable option is set" do
      attr = described_class.new(:rating, type: :float, sortable: true)
      expect(attr.sortable?).to be(true)
    end

    it "returns false when sortable option is not set" do
      attr = described_class.new(:rating, type: :float)
      expect(attr.sortable?).to be(false)
    end

    it "returns false when sortable is explicitly false" do
      attr = described_class.new(:rating, type: :float, sortable: false)
      expect(attr.sortable?).to be(false)
    end
  end

  describe "inherits Field behavior" do
    it "supports association columns" do
      attr = described_class.new("channel.id", type: :integer)
      expect(attr.association?).to be(true)
      expect(attr.association_name).to eq(:channel)
      expect(attr.column_name).to eq(:id)
    end

    it "supports sql columns" do
      attr = described_class.new("(SELECT COUNT(*) FROM tags)", type: :integer, as: :tag_count)
      expect(attr.sql?).to be(true)
      expect(attr.name).to eq(:tag_count)
    end
  end
end
