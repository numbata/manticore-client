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

    # Lazy, enumerable result set. Defers the ManticoreSearch HTTP call until results are accessed.
    class Result
      include Enumerable

      attr_reader :index, :query, :options

      def initialize(index, query, options = {})
        @index = index
        @query = query
        @options = options
        @populated = false
        @mutex = Mutex.new
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

      # Returns term counts grouped by the requested attribute(s).
      # Issues a dedicated limit:0 request sharing the same query and filters.
      def facets(*fields, size: 1000)
        return {} if fields.empty?

        aggs = fields.to_h do |field|
          [field.to_s, ManticoreClient::Client::Aggregation.new(
            terms: ManticoreClient::Client::AggTerms.new(field: field.to_s, size: size)
          )]
        end

        response = @mutex.synchronize { execute_request(build_search_request(aggs: aggs, limit: 0)) }
        raw = response.aggregations || {}

        fields.each_with_object({}) do |field, result|
          buckets = raw.dig(field.to_sym, :buckets) || raw.dig(field.to_s, "buckets") || []
          result[field.to_sym] = buckets.to_h do |bucket|
            [bucket[:key] || bucket["key"], bucket[:doc_count] || bucket["doc_count"]]
          end
        end
      end

      private

        def populate
          return if @populated

          @mutex.synchronize do
            return if @populated

            response = execute_request(build_search_request)

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
        end

        def execute_request(request)
          api = ManticoreClient::Client::SearchApi.new
          if defined?(ActiveSupport::Notifications)
            ActiveSupport::Notifications.instrument("search.manticore_rails", table: index.table_name) do
              api.search(request)
            end
          else
            api.search(request)
          end
        end

        def build_search_request(aggs: nil, limit: nil)
          query_params = build_query
          sort_params = options[:order] ? build_sort(options[:order]) : nil

          attrs = {
            table: index.table_name,
            query: query_params,
            limit: limit || per_page,
            offset: offset
          }
          attrs[:sort] = sort_params if sort_params
          attrs[:aggs] = aggs if aggs

          ManticoreClient::Client::SearchRequest.new(**attrs)
        end

        def build_query
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
