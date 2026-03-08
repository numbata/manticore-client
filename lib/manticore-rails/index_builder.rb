# frozen_string_literal: true

module ManticoreRails
  # DSL builder for defining ManticoreSearch indexes on ActiveRecord models.
  # Evaluated via +instance_eval+ inside {Searchable::ClassMethods#define_manticore_index}.
  #
  # Uses +method_missing+ to support dot-notation association traversal
  # (e.g. +tags.name+) via {AssociationProxy}.
  #
  # @example
  #   define_manticore_index do
  #     indexes :title, :body
  #     indexes tags.name
  #     has :status, type: :integer
  #     set_property min_infix_len: 3
  #   end
  class IndexBuilder
    def initialize(&block)
      @field_definitions = []
      @attribute_definitions = []
      @reindex_association_list = []
      @extra_includes = []
      @property_hash = {}
      instance_eval(&block) if block
    end

    # Declares one or more full-text search fields.
    # @param columns [Array<Symbol, String>] column names or association paths
    # @param options [Hash] field options (e.g. +as:+ for aliasing)
    def indexes(*columns, **options)
      columns.each do |col|
        @field_definitions << [normalize_column(col), options]
      end
    end

    # Declares one or more filterable/sortable attributes.
    # @param columns [Array<Symbol, String>] column names or association paths
    # @param options [Hash] attribute options (requires +type:+)
    def has(*columns, **options)
      columns.each do |col|
        @attribute_definitions << [normalize_column(col), options]
      end
    end

    # Declares associations whose changes should trigger reindexing of
    # the parent record.
    # @param associations [Array<Symbol, String>] association names
    def reindex_on_change(*associations)
      associations.each do |assoc|
        @reindex_association_list << assoc.to_s
      end
    end

    # Declares extra associations to eager-load during batch indexing.
    # Use this when +manticore_serialize+ accesses associations that aren't
    # declared as index fields (e.g. associations used only in custom serialization).
    # @param associations [Array<Symbol, Hash>] association names suitable for ActiveRecord's +includes+
    # @example
    #   includes :transcripts, anchors: :dvags
    def includes(*associations)
      @extra_includes.concat(associations)
    end

    # Sets ManticoreSearch table properties (e.g. +min_infix_len+, +morphology+).
    # @param hash [Hash] property key-value pairs
    def set_property(hash)
      @property_hash.merge!(hash)
    end

    # Builds an {Index} from the accumulated definitions.
    # @param model_class [Class] the ActiveRecord model class
    # @return [Index]
    def build(model_class)
      index = Index.new(model_class)

      @field_definitions.each { |col, opts| index.add_field(col, opts) }
      @attribute_definitions.each { |col, opts| index.add_attribute(col, opts) }
      @reindex_association_list.each { |assoc| index.add_reindex_association(assoc) }
      @extra_includes.each { |assoc| index.add_extra_include(assoc) }
      index.set_property(@property_hash) unless @property_hash.empty?

      index
    end

    private

      def normalize_column(col)
        col.is_a?(Symbol) ? col : col.to_s
      end

      # Enables dot-notation DSL for association traversal.
      # Unknown method calls with arguments produce SQL function strings
      # (e.g. +tags(:company_id)+ → +"tags(company_id)"+).
      # Without arguments, returns an {AssociationProxy}.
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
