# frozen_string_literal: true

module ManticoreRails
  class IndexBuilder
    def initialize(&block)
      @field_definitions = []
      @attribute_definitions = []
      @reindex_association_list = []
      @extra_includes = []
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

    # Extra associations to eager-load during batch indexing, beyond those declared as index fields.
    def includes(*associations)
      @extra_includes.concat(associations)
    end

    def set_property(hash)
      @property_hash.merge!(hash)
    end

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

      def method_missing(name, *args)
        if args.any?
          warn "[ManticoreRails] '#{name}' is not a known DSL method — if this is a typo, " \
               "the field will not be registered. Use a string literal for SQL expressions."
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
