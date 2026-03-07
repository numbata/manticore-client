# frozen_string_literal: true

module ManticoreRails
  class Searcher
    class << self
      def search(index, query, options = {})
        Result.new(index, query, options)
      end

      def search_for_ids(index, query, options = {})
        Result.new(index, query, options.merge(ids_only: true))
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
        populate
        @matches
      end

      def to_a
        populate
        @items
      end

      def each(&block)
        to_a.each(&block)
      end

      # Pagination

      def current_page
        page = options[:page].to_i
        [page, 1].max
      end

      def per_page
        [(options[:per_page] || options[:limit] || 20).to_i, 1].max
      end

      def offset
        options[:offset] || ((current_page - 1) * per_page)
      end

      def total_entries
        populate
        @total_entries || 0
      end

      def total_pages
        return 0 if total_entries.zero?

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
          api.search(request)
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

          # Add filters from :with option
          if options[:with].is_a?(Hash) && !options[:with].empty?
            filter_queries = options[:with].map { |attr, value| build_filter(attr, value) }
            base_filter = if base.query_string
              ManticoreClient::Client::QueryFilter.new(query_string: base.query_string)
            else
              ManticoreClient::Client::QueryFilter.new(match_all: base.match_all)
            end
            ManticoreClient::Client::SearchQuery.new(
              bool: ManticoreClient::Client::BoolFilter.new(
                must: [base_filter, *filter_queries]
              )
            )
          else
            base
          end
        end

        def build_filter(attr, value)
          case value
          when Range
            upper_bound = value.exclude_end? ? :lt : :lte
            bounds = { gte: coerce_filter_value(value.begin), upper_bound => coerce_filter_value(value.end) }
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

        def coerce_filter_value(value)
          case value
          when Time, DateTime
            value.to_i
          else
            value
          end
        end
    end
  end
end
