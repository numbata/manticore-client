# frozen_string_literal: true

module ManticoreRails
  class Index
    attr_reader :model_class, :fields, :attributes, :properties, :reindex_associations

    def initialize(model_class)
      @model_class = model_class
      @fields = []
      @attributes = []
      @properties = {}
      @reindex_associations = []
    end

    def add_field(column, options = {})
      @fields << Field.new(column, options)
    end

    def add_attribute(column, options = {})
      @attributes << Attribute.new(column, options)
    end

    def add_reindex_association(association)
      @reindex_associations << association
    end

    def set_property(hash)
      @properties.merge!(hash)
    end

    def indexable_fields
      @indexable_fields ||= fields.reject(&:sql?)
    end

    def indexable_attributes
      @indexable_attributes ||= attributes.reject(&:sql?)
    end

    def table_name
      ManticoreRails.configuration.table_name_for(model_class.table_name)
    end

    # All unique association includes from fields and attributes.
    # Returns a flat array suitable for ActiveRecord's `includes`.
    # Simple associations return symbols, nested ones return hashes.
    def referenced_associations
      paths = (fields + attributes)
              .select(&:association?)
              .map { |f| f.association_path[0...-1] }
              .uniq

      paths.map { |p| p.size == 1 ? p.first : nest_path(p) }
    end

    private

      def nest_path(parts)
        parts.reverse.inject { |inner, outer| { outer => inner } }
      end
  end

  class Field
    attr_reader :column, :options

    def initialize(column, options = {})
      @column = column
      @options = options
    end

    def name
      (options[:as] || column_name).to_sym
    end

    SQL_KEYWORDS = /\b(?:SELECT|CAST|IF|CONVERT|GROUP_CONCAT|CONCAT|LOWER|UPPER|UNIX_TIMESTAMP)\b/i.freeze
    SQL_FUNCTION = /\A\w+\(.*\)\z/.freeze

    def sql?
      column.is_a?(String) && (
        column.strip.start_with?("(") ||
        column.match?(SQL_KEYWORDS) ||
        column.match?(SQL_FUNCTION)
      )
    end

    def association?
      !sql? && column.to_s.include?(".")
    end

    def method_call?
      column.is_a?(Symbol) && !association?
    end

    def association_name
      return nil unless association?

      column_parts.first
    end

    def column_name
      if association?
        column_parts.last
      elsif sql?
        options[:as] || :unknown
      else
        column.to_sym
      end
    end

    def association_path
      return [] unless association?

      column_parts
    end

    def manticore_type
      :text
    end

    private

      def column_parts
        @column_parts ||= column.to_s.split(".").map(&:to_sym)
      end
  end

  class Attribute < Field
    TYPE_MAP = {
      integer: :bigint,
      datetime: :timestamp,
      boolean: :bool,
      float: :float,
      string: :string,
      text: :text,
      json: :json
    }.freeze

    def type
      options[:type] || :string
    end

    def manticore_type
      TYPE_MAP[type] || :string
    end

    def sortable?
      !!options[:sortable]
    end
  end
end
