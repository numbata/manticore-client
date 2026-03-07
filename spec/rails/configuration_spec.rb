# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ManticoreRails::Configuration do
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

  describe "validation" do
    it "rejects batch_size of 0" do
      expect { config.batch_size = 0 }.to raise_error(ArgumentError, /batch_size must be positive/)
    end

    it "rejects negative batch_size" do
      expect { config.batch_size = -1 }.to raise_error(ArgumentError, /batch_size must be positive/)
    end

    it "rejects index_prefix with special characters" do
      expect { config.index_prefix = "bad prefix!" }.to raise_error(ArgumentError, /alphanumeric/)
    end

    it "accepts nil index_prefix" do
      config.index_prefix = "test_"
      config.index_prefix = nil
      expect(config.index_prefix).to be_nil
    end
  end

  describe "#on_error" do
    it "defaults to a warn lambda" do
      expect(config.on_error).to be_a(Proc)
    end

    it "accepts :raise to re-raise errors" do
      config.on_error = :raise
      expect { config.on_error.call("test", RuntimeError.new("boom")) }.to raise_error(RuntimeError, "boom")
    end

    it "accepts a custom lambda" do
      messages = []
      config.on_error = ->(msg, _err) { messages << msg }
      config.on_error.call("hello", StandardError.new)
      expect(messages).to eq(["hello"])
    end

    it "accepts nil to disable error handling" do
      config.on_error = nil
      expect(config.on_error).to be_nil
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
