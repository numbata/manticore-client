# frozen_string_literal: true

module Manticore
  module Rails
    class Searcher
      class << self
        def search(index, query, options = {})
          Result.new(index, query, options)
        end

        def search_for_ids(index, query, options = {})
          Result.new(index, query, options.merge(ids_only: true))
        end
      end
    end

    class Result
      include Enumerable

      attr_reader :index, :query, :options

      def initialize(index, query, options = {})
        @index = index
        @query = query
        @options = options
        @populated = false
      end

      def matches
        populate unless @populated
        @matches
      end

      def to_a
        populate unless @populated
        @items
      end

      def each(&block)
        to_a.each(&block)
      end

      # Pagination

      def current_page
        page = options[:page].to_i
        page < 1 ? 1 : page
      end

      def per_page
        (options[:per_page] || options[:limit] || 20).to_i
      end

      def offset
        options[:offset] || ((current_page - 1) * per_page)
      end

      def total_entries
        populate unless @populated
        @total_entries || 0
      end

      def total_pages
        return 0 if total_entries == 0

        (total_entries.to_f / per_page).ceil
      end

      def next_page
        current_page >= total_pages ? nil : current_page + 1
      end

      def previous_page
        current_page <= 1 ? nil : current_page - 1
      end

      private

      def populate
        return if @populated

        response = execute_search
        hits = response.hits

        @total_entries = hits.total || 0
        @matches = hits.hits || []

        if options[:ids_only]
          @items = @matches.map { |h| h._id.to_i }
        else
          ids = @matches.map { |h| h._id.to_i }
          @items = ids.empty? ? [] : index.model_class.where(id: ids).to_a
        end

        @populated = true
      end

      def execute_search
        api = Manticore::Client::SearchApi.new
        request = build_search_request
        api.search(request)
      end

      def build_search_request
        query_params = build_query
        sort_params = options[:order] ? build_sort(options[:order]) : nil

        Manticore::Client::SearchRequest.new(
          table: index.table_name,
          query: query_params,
          limit: per_page,
          offset: offset,
          sort: sort_params
        )
      end

      def build_query
        # Base query
        base = if query && !query.empty?
          Manticore::Client::SearchQuery.new(query_string: query)
        else
          Manticore::Client::SearchQuery.new(match_all: {})
        end

        # Add filters from :with option
        if options[:with].is_a?(Hash) && !options[:with].empty?
          filter_queries = options[:with].map { |attr, value| build_filter(attr, value) }
          # Wrap in bool.must with the original query + filters
          Manticore::Client::SearchQuery.new(
            bool: Manticore::Client::BoolFilter.new(
              must: [
                Manticore::Client::QueryFilter.new(query_string: base.query_string, match_all: base.match_all),
                *filter_queries
              ]
            )
          )
        else
          base
        end
      end

      def build_filter(attr, value)
        case value
        when Range
          Manticore::Client::QueryFilter.new(
            range: { attr => { gte: coerce_filter_value(value.begin), lte: coerce_filter_value(value.end) } }
          )
        when Array
          Manticore::Client::QueryFilter.new(
            _in: { attr => value.map { |v| coerce_filter_value(v) } }
          )
        else
          Manticore::Client::QueryFilter.new(
            equals: { attr => coerce_filter_value(value) }
          )
        end
      end

      def build_sort(order)
        case order
        when Hash
          order.map { |field, dir| { field => dir.to_s } }
        when String
          order.split(",").map do |part|
            field, dir = part.strip.split(/\s+/)
            { field => (dir || "asc").downcase }
          end
        else
          []
        end
      end

      def coerce_filter_value(value)
        case value
        when Time, DateTime
          value.to_i
        when NilClass
          0
        else
          value
        end
      end
    end
  end
end
