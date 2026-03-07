# frozen_string_literal: true

module ManticoreRails
  # Builds and executes search queries against ManticoreSearch.
  # Returns lazy {Result} objects that defer execution until enumeration.
  #
  # @example Full-text search with filters
  #   Searcher.search(index, "ruby", with: { status: 1 }, page: 2, per_page: 10)
  class Searcher
    class << self
      # Performs a full-text search and returns hydrated ActiveRecord objects.
      # @param index [Index] the index definition to search
      # @param query [String] the search query string
      # @param options [Hash] search options (+:with+, +:without+, +:order+, +:page+, +:per_page+)
      # @return [Result] a lazy, enumerable result set
      def search(index, query, options = {})
        Result.new(index, query, options)
      end

      # Performs a full-text search and returns only record IDs.
      # @param index [Index] the index definition to search
      # @param query [String] the search query string
      # @param options [Hash] search options (same as {search})
      # @return [Result] a lazy result set yielding Integer IDs
      def search_for_ids(index, query, options = {})
        Result.new(index, query, options.merge(ids_only: true))
      end
    end

    # Lazy, enumerable search result set with pagination support.
    # Defers the actual ManticoreSearch HTTP call until results are accessed.
    #
    # @example Iterating results
    #   result = Searcher.search(index, "test")
    #   result.each { |record| puts record.title }
    #   result.total_entries  #=> 42
    #   result.total_pages    #=> 3
    class Result
      include Enumerable

      # @return [Index] the index definition this result queries
      # @return [String] the search query string
      # @return [Hash] the search options
      attr_reader :index, :query, :options

      # @param index [Index]
      # @param query [String]
      # @param options [Hash]
      def initialize(index, query, options = {})
        @index = index
        @query = query
        @options = options
        @populated = false
      end

      # Raw ManticoreSearch hit objects from the response.
      # @return [Array] raw hits from ManticoreSearch
      def matches
        populate
        @matches
      end

      # Hydrated ActiveRecord records (or IDs if +ids_only+).
      # @return [Array<ActiveRecord::Base>, Array<Integer>]
      def to_a
        populate
        @items
      end

      # Yields each record (or ID) in the result set.
      # @yield [record] each hydrated record or ID
      def each(&block)
        to_a.each(&block)
      end

      # @!group Pagination

      # The current page number (minimum 1).
      # @return [Integer]
      def current_page
        page = options[:page].to_i
        [page, 1].max
      end

      # Results per page (minimum 1, default 20).
      # @return [Integer]
      def per_page
        [(options[:per_page] || options[:limit] || 20).to_i, 1].max
      end

      # The offset for the current page.
      # @return [Integer]
      def offset
        options[:offset] || ((current_page - 1) * per_page)
      end

      # Total number of matching documents in ManticoreSearch.
      # @return [Integer]
      def total_entries
        populate
        @total_entries || 0
      end

      # Total number of pages based on {total_entries} and {per_page}.
      # @return [Integer]
      def total_pages
        return 0 if total_entries.zero?

        (total_entries.to_f / per_page).ceil
      end

      # The next page number, or +nil+ if on the last page.
      # @return [Integer, nil]
      def next_page
        current_page >= total_pages ? nil : current_page + 1
      end

      # The previous page number, or +nil+ if on the first page.
      # @return [Integer, nil]
      def previous_page
        current_page <= 1 ? nil : current_page - 1
      end

      # @!endgroup

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
            @items = if ids.empty?
              []
            else
              records_by_id = index.model_class.where(id: ids).index_by(&:id)
              ids.filter_map { |id| records_by_id[id] }
            end
          end

          @populated = true
        end

        def execute_search
          api = ManticoreClient::Client::SearchApi.new
          request = build_search_request
          if defined?(ActiveSupport::Notifications)
            ActiveSupport::Notifications.instrument("search.manticore_rails", table: index.table_name) do
              api.search(request)
            end
          else
            api.search(request)
          end
        end

        def build_search_request
          query_params = build_query
          sort_params = options[:order] ? build_sort(options[:order]) : nil

          attrs = {
            table: index.table_name,
            query: query_params,
            limit: per_page,
            offset: offset
          }
          attrs[:sort] = sort_params if sort_params

          ManticoreClient::Client::SearchRequest.new(**attrs)
        end

        def build_query
          # Base query
          base = if query && !query.empty?
            ManticoreClient::Client::SearchQuery.new(query_string: query)
          else
            ManticoreClient::Client::SearchQuery.new(match_all: {})
          end

          must_filters = build_filters_from(options[:with])
          must_not_filters = build_filters_from(options[:without])

          if must_filters.any? || must_not_filters.any?
            base_filter = if base.query_string
              ManticoreClient::Client::QueryFilter.new(query_string: base.query_string)
            else
              ManticoreClient::Client::QueryFilter.new(match_all: base.match_all)
            end

            bool_params = { must: [base_filter, *must_filters] }
            bool_params[:must_not] = must_not_filters if must_not_filters.any?

            ManticoreClient::Client::SearchQuery.new(
              bool: ManticoreClient::Client::BoolFilter.new(**bool_params)
            )
          else
            base
          end
        end

        def build_filter(attr, value)
          case value
          when Range
            upper_bound = value.exclude_end? ? :lt : :lte
            bounds = {}
            bounds[:gte] = coerce_filter_value(value.begin) unless value.begin.nil?
            bounds[upper_bound] = coerce_filter_value(value.end) unless value.end.nil?
            ManticoreClient::Client::QueryFilter.new(range: { attr => bounds })
          when Array
            ManticoreClient::Client::QueryFilter.new(
              _in: { attr => value.map { |v| coerce_filter_value(v) } }
            )
          else
            ManticoreClient::Client::QueryFilter.new(
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

        def build_filters_from(hash)
          return [] unless hash.is_a?(Hash) && !hash.empty?

          hash.map { |attr, value| build_filter(attr, value) }
        end

        def coerce_filter_value(value)
          case value
          when Time, DateTime, Date
            value.to_time.to_i
          else
            value
          end
        end
    end
  end
end
