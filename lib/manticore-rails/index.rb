# frozen_string_literal: true

module ManticoreRails
  # Represents a ManticoreSearch index definition for an ActiveRecord model.
  # Built by {IndexBuilder} and frozen upon registration in {Registry}.
  class Index
    # @return [Class] the ActiveRecord model class this index belongs to
    # @return [Array<Field>] full-text search fields
    # @return [Array<Attribute>] filterable/sortable attributes
    # @return [Hash] ManticoreSearch table properties (e.g. morphology)
    # @return [Array<String>] association names that trigger reindexing
    attr_reader :model_class, :fields, :attributes, :properties, :reindex_associations

    # @param model_class [Class] ActiveRecord model class
    def initialize(model_class)
      @model_class = model_class
      @fields = []
      @attributes = []
      @properties = {}
      @reindex_associations = []
    end

    # @param column [Symbol, String] column name or dot-notation association path
    # @param options [Hash] field options (e.g. +as:+ for aliasing)
    # @raise [FrozenError] if the index has been frozen
    def add_field(column, options = {})
      raise FrozenError, "can't modify frozen #{self.class}" if @frozen

      @fields << Field.new(column, options)
    end

    # @param column [Symbol, String] column name or dot-notation association path
    # @param options [Hash] attribute options (requires +type:+)
    # @raise [FrozenError] if the index has been frozen
    def add_attribute(column, options = {})
      raise FrozenError, "can't modify frozen #{self.class}" if @frozen

      @attributes << Attribute.new(column, options)
    end

    # @param association [String] association name for reindex-on-change callbacks
    # @raise [FrozenError] if the index has been frozen
    def add_reindex_association(association)
      raise FrozenError, "can't modify frozen #{self.class}" if @frozen

      @reindex_associations << association
    end

    # Merges ManticoreSearch table properties (e.g. +min_infix_len+, +morphology+).
    # @param hash [Hash] property key-value pairs
    # @raise [FrozenError] if the index has been frozen
    def set_property(hash)
      raise FrozenError, "can't modify frozen #{self.class}" if @frozen

      @properties.merge!(hash)
    end

    # Freezes the index definition, preventing further modification.
    # Called automatically by {Registry#register}.
    # @return [self]
    def freeze!
      @frozen = true
      @fields.freeze
      @attributes.freeze
      @properties.freeze
      @reindex_associations.freeze
      self
    end

    # @return [Boolean] whether this index has been frozen
    def frozen?
      !!@frozen
    end

    # Fields that should be serialized (excludes SQL expressions).
    # @return [Array<Field>]
    def indexable_fields
      @indexable_fields ||= fields.reject(&:sql?)
    end

    # Attributes that should be serialized (excludes SQL expressions).
    # @return [Array<Attribute>]
    def indexable_attributes
      @indexable_attributes ||= attributes.reject(&:sql?)
    end

    # The ManticoreSearch table name, including any configured prefix.
    # @return [String]
    def table_name
      ManticoreRails.configuration.table_name_for(model_class.table_name)
    end

    # Unique association includes from fields and attributes.
    # @return [Array<Symbol, Hash>] suitable for ActiveRecord's +includes+
    def referenced_associations
      @referenced_associations ||= begin
        paths = (fields + attributes)
                .select(&:association?)
                .map { |f| f.association_path[0...-1] }
                .uniq

        paths.map { |p| p.size == 1 ? p.first : nest_path(p) }
      end
    end

    private

      def nest_path(parts)
        parts.reverse.inject { |inner, outer| { outer => inner } }
      end
  end

  # Represents a full-text search field in a ManticoreSearch index.
  class Field
    # @return [Symbol, String] the raw column definition
    # @return [Hash] field options (+:as+ for aliasing)
    attr_reader :column, :options

    # @param column [Symbol, String] column name, dot-notation path, or SQL expression
    # @param options [Hash] field options
    def initialize(column, options = {})
      @column = column
      @options = options
    end

    # The field name used in the ManticoreSearch schema.
    # @return [Symbol]
    def name
      (options[:as] || column_name).to_sym
    end

    # @!visibility private
    SQL_KEYWORDS = /\b(?:SELECT|CAST|IF|CONVERT|GROUP_CONCAT|CONCAT|LOWER|UPPER|UNIX_TIMESTAMP)\b/i
    # @!visibility private
    SQL_FUNCTION = /\A\w+\(.*\)\z/

    # Whether this field is a raw SQL expression.
    # @return [Boolean]
    def sql?
      column.is_a?(String) && (
        column.strip.start_with?("(") ||
        column.match?(SQL_KEYWORDS) ||
        column.match?(SQL_FUNCTION)
      )
    end

    # Whether this field references an association via dot notation.
    # @return [Boolean]
    def association?
      !sql? && column.to_s.include?(".")
    end

    # The root association name (e.g. +:tags+ from +"tags.name"+).
    # @return [Symbol, nil]
    def association_name
      return nil unless association?

      column_parts.first
    end

    # The terminal column name.
    # @return [Symbol]
    def column_name
      if association?
        column_parts.last
      elsif sql?
        options[:as] || :unknown
      else
        column.to_sym
      end
    end

    # The full dot-notation path as an array of symbols.
    # @return [Array<Symbol>]
    def association_path
      return [] unless association?

      column_parts
    end

    # The ManticoreSearch column type.
    # @return [Symbol]
    def manticore_type
      :text
    end

    private

      def column_parts
        @column_parts ||= column.to_s.split(".").map(&:to_sym)
      end
  end

  # Represents a filterable/sortable attribute in a ManticoreSearch index.
  # Inherits full-text field behavior from {Field} and adds type mapping.
  class Attribute < Field
    # Maps Ruby types to ManticoreSearch column types.
    TYPE_MAP = {
      integer: :bigint,
      datetime: :timestamp,
      boolean: :bool,
      float: :float,
      string: :string,
      text: :text,
      json: :json
    }.freeze

    # The Ruby type declared in the index definition.
    # @return [Symbol]
    def type
      options[:type] || :string
    end

    # The corresponding ManticoreSearch column type.
    # @return [Symbol]
    def manticore_type
      TYPE_MAP[type] || :string
    end
  end
end
