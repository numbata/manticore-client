# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Manticore::Rails::Searcher do
  let(:model_class) { Struct.new(:table_name).new("episodes") }
  let(:index) { Manticore::Rails::Index.new(model_class) }

  before do
    Manticore::Rails.configuration.index_prefix = nil
    index.add_field(:name)
    index.add_attribute(:id, type: :integer)
  end

  describe ".search" do
    it "returns a Result" do
      result = described_class.search(index, "test query")
      expect(result).to be_a(Manticore::Rails::Result)
    end
  end

  describe ".search_for_ids" do
    it "returns a Result with ids_only option" do
      result = described_class.search_for_ids(index, "test query")
      expect(result.options[:ids_only]).to be(true)
    end
  end
end

RSpec.describe Manticore::Rails::Result do
  let(:model_class) { Struct.new(:table_name).new("episodes") }
  let(:index) { Manticore::Rails::Index.new(model_class) }
  let(:search_api) { instance_double(Manticore::Client::SearchApi) }

  before do
    Manticore::Rails.configuration.index_prefix = nil
    allow(Manticore::Client::SearchApi).to receive(:new).and_return(search_api)
  end

  def mock_search_response(total:, hits: [])
    hit_objects = hits.map do |h|
      double("hit", _id: h[:id].to_s, _score: 1, _source: h[:source] || {})
    end
    hits_obj = double("hits", total: total, hits: hit_objects)
    double("response", hits: hits_obj)
  end

  def stub_search(total:, hits: [])
    allow(search_api).to receive(:search).and_return(mock_search_response(total: total, hits: hits))
  end

  describe "pagination" do
    it "defaults to page 1" do
      result = described_class.new(index, "test")
      expect(result.current_page).to eq(1)
    end

    it "defaults to 20 per page" do
      result = described_class.new(index, "test")
      expect(result.per_page).to eq(20)
    end

    it "calculates offset from page" do
      result = described_class.new(index, "test", page: 3, per_page: 10)
      expect(result.offset).to eq(20)
    end

    it "calculates total_pages" do
      stub_search(total: 55)
      result = described_class.new(index, "test", per_page: 10)
      expect(result.total_pages).to eq(6)
    end

    it "returns nil for next_page on last page" do
      stub_search(total: 10)
      result = described_class.new(index, "test", per_page: 10, page: 1)
      expect(result.next_page).to be_nil
    end

    it "returns next_page when not on last page" do
      stub_search(total: 30)
      result = described_class.new(index, "test", per_page: 10, page: 1)
      expect(result.next_page).to eq(2)
    end

    it "returns nil for previous_page on first page" do
      result = described_class.new(index, "test", page: 1)
      expect(result.previous_page).to be_nil
    end

    it "returns previous_page when not on first page" do
      result = described_class.new(index, "test", page: 3)
      expect(result.previous_page).to eq(2)
    end

    it "returns total_entries from response" do
      stub_search(total: 42)
      result = described_class.new(index, "test")
      expect(result.total_entries).to eq(42)
    end
  end

  describe "ids_only mode" do
    it "returns array of integer IDs" do
      stub_search(total: 3, hits: [{ id: 1 }, { id: 2 }, { id: 3 }])
      result = described_class.new(index, "test", ids_only: true)
      expect(result.to_a).to eq([1, 2, 3])
    end
  end

  describe "Enumerable" do
    it "supports each" do
      stub_search(total: 2, hits: [{ id: 1 }, { id: 2 }])
      result = described_class.new(index, "test", ids_only: true)
      collected = []
      result.each { |item| collected << item }
      expect(collected).to eq([1, 2])
    end
  end

  describe "search request building" do
    it "sends query_string for non-empty query" do
      stub_search(total: 0)
      described_class.new(index, "test query").to_a

      expect(search_api).to have_received(:search) do |request|
        expect(request).to be_a(Manticore::Client::SearchRequest)
        expect(request.table).to eq("episodes")
        expect(request.query.query_string).to eq("test query")
      end
    end

    it "uses match_all for empty query" do
      stub_search(total: 0)
      described_class.new(index, "").to_a

      expect(search_api).to have_received(:search) do |request|
        expect(request.query.match_all).to eq({})
      end
    end

    it "builds range filters in bool.must" do
      stub_search(total: 0)
      described_class.new(index, "test", with: { beginning: 100..200 }).to_a

      expect(search_api).to have_received(:search) do |request|
        bool = request.query.bool
        expect(bool).to be_a(Manticore::Client::BoolFilter)
        range_filter = bool.must.find { |f| f.range }
        expect(range_filter.range).to eq({ beginning: { gte: 100, lte: 200 } })
      end
    end

    it "builds array filters using _in" do
      stub_search(total: 0)
      described_class.new(index, "test", with: { channel_id: [1, 2, 3] }).to_a

      expect(search_api).to have_received(:search) do |request|
        bool = request.query.bool
        in_filter = bool.must.find { |f| f._in }
        expect(in_filter._in).to eq({ channel_id: [1, 2, 3] })
      end
    end

    it "builds equals filters for scalars" do
      stub_search(total: 0)
      described_class.new(index, "test", with: { channel_id: 42 }).to_a

      expect(search_api).to have_received(:search) do |request|
        bool = request.query.bool
        eq_filter = bool.must.find { |f| f.equals }
        expect(eq_filter.equals).to eq({ channel_id: 42 })
      end
    end

    it "coerces Time values in filters" do
      time = Time.new(2024, 1, 15, 12, 0, 0)
      stub_search(total: 0)
      described_class.new(index, "test", with: { beginning: time }).to_a

      expect(search_api).to have_received(:search) do |request|
        bool = request.query.bool
        eq_filter = bool.must.find { |f| f.equals }
        expect(eq_filter.equals).to eq({ beginning: time.to_i })
      end
    end

    it "handles order as Hash" do
      stub_search(total: 0)
      described_class.new(index, "test", order: { beginning: :desc }).to_a

      expect(search_api).to have_received(:search) do |request|
        expect(request.sort).to eq([{ beginning: "desc" }])
      end
    end

    it "handles order as String" do
      stub_search(total: 0)
      described_class.new(index, "test", order: "beginning DESC").to_a

      expect(search_api).to have_received(:search) do |request|
        expect(request.sort).to eq([{ "beginning" => "desc" }])
      end
    end
  end
end
