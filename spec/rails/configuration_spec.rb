# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreClient::Rails::Configuration do
  subject(:config) { described_class.new }

  describe "default values" do
    it "has nil index_prefix" do
      expect(config.index_prefix).to be_nil
    end

    it "has batch_size of 1000" do
      expect(config.batch_size).to eq(1000)
    end

    it "has auto_indexing enabled" do
      expect(config.auto_indexing).to be(true)
    end

    it "has async_indexing disabled" do
      expect(config.async_indexing).to be(false)
    end

    it "has nil index_job_class" do
      expect(config.index_job_class).to be_nil
    end
  end

  describe "custom values" do
    it "allows setting index_prefix" do
      config.index_prefix = "prod_"
      expect(config.index_prefix).to eq("prod_")
    end

    it "allows setting batch_size" do
      config.batch_size = 500
      expect(config.batch_size).to eq(500)
    end

    it "allows setting auto_indexing" do
      config.auto_indexing = false
      expect(config.auto_indexing).to be(false)
    end

    it "allows setting async_indexing" do
      config.async_indexing = true
      expect(config.async_indexing).to be(true)
    end

    it "allows setting index_job_class" do
      config.index_job_class = "MyIndexJob"
      expect(config.index_job_class).to eq("MyIndexJob")
    end
  end

  describe "#table_name_for" do
    context "without prefix" do
      it "returns the name as-is" do
        expect(config.table_name_for("articles")).to eq("articles")
      end
    end

    context "with prefix" do
      before { config.index_prefix = "prod_" }

      it "prepends the prefix to the name" do
        expect(config.table_name_for("articles")).to eq("prod_articles")
      end
    end
  end
end
