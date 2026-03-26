# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreRails::Registry do
  subject(:registry) { described_class.instance }

  after { registry.reset! }

  let(:klass) { Class.new { def self.table_name = "articles" } }
  let(:another_klass) { Class.new { def self.table_name = "users" } }
  let(:fake_index) { ManticoreRails::Index.new(klass) }
  let(:another_index) { ManticoreRails::Index.new(another_klass) }

  describe "#register" do
    it "stores an index for a class" do
      registry.register(klass, fake_index)
      expect(registry.find_by_class(klass)).to eq(fake_index)
    end
  end

  describe "#all" do
    it "returns all registered indexes" do
      registry.register(klass, fake_index)
      registry.register(another_klass, another_index)
      expect(registry.all).to contain_exactly(fake_index, another_index)
    end

    it "returns empty array when nothing registered" do
      expect(registry.all).to be_empty
    end
  end

  describe "#find_by_class" do
    it "returns the index for the given class" do
      registry.register(klass, fake_index)
      expect(registry.find_by_class(klass)).to eq(fake_index)
    end

    it "returns nil for unregistered class" do
      expect(registry.find_by_class(klass)).to be_nil
    end

    it "finds index via ancestor (STI support)" do
      parent = Class.new
      child = Class.new(parent)
      registry.register(parent, fake_index)
      expect(registry.find_by_class(child)).to eq(fake_index)
    end
  end

  describe "#find_by_table" do
    it "returns the index matching the table name" do
      registry.register(klass, fake_index)
      registry.register(another_klass, another_index)
      expect(registry.find_by_table("users")).to eq(another_index)
    end

    it "returns nil when no index matches" do
      expect(registry.find_by_table("nonexistent")).to be_nil
    end
  end

  describe "#reset!" do
    it "clears all registered indexes" do
      registry.register(klass, fake_index)
      registry.reset!
      expect(registry.all).to be_empty
    end
  end
end
