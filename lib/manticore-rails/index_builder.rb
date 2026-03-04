# frozen_string_literal: true

module ManticoreClient
  module Rails
    class IndexBuilder
      attr_reader :field_definitions, :attribute_definitions, :reindex_association_list, :property_hash

      def initialize(&block)
        @field_definitions = []
        @attribute_definitions = []
        @reindex_association_list = []
        @property_hash = {}
        instance_eval(&block) if block
      end

      def indexes(*columns, **options)
        columns.each do |col|
          @field_definitions << [normalize_column(col), options]
        end
      end

      def has(*columns, **options)
        columns.each do |col|
          @attribute_definitions << [normalize_column(col), options]
        end
      end

      def reindex_on_change(*associations)
        associations.each do |assoc|
          @reindex_association_list << assoc.to_s
        end
      end

      def set_property(hash)
        @property_hash.merge!(hash)
      end

      def build(model_class)
        index = Index.new(model_class)

        @field_definitions.each { |col, opts| index.add_field(col, opts) }
        @attribute_definitions.each { |col, opts| index.add_attribute(col, opts) }
        @reindex_association_list.each { |assoc| index.add_reindex_association(assoc) }
        index.set_property(@property_hash) unless @property_hash.empty?

        index
      end

      private

      def normalize_column(col)
        case col
        when Symbol
          col
        when String, AssociationProxy
          col.to_s
        else
          col.to_s
        end
      end

      def method_missing(name, *args)
        if args.any?
          # tags(:company_id) → "tags(company_id)"
          "#{name}(#{args.first})"
        else
          AssociationProxy.new(name)
        end
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end
    end
  end
end
