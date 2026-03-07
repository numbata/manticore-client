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

    def table_name
      ManticoreRails.configuration.table_name_for(model_class.table_name)
    end

    # All unique association names from fields and attributes
    def referenced_associations
      (fields + attributes)
        .select(&:association?)
        .map(&:association_name)
        .uniq
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

    def sql?
      column.is_a?(String) && (
        column.strip.start_with?("(") ||
        column.match?(/\b(?:SELECT|CAST|IF|CONVERT|GROUP_CONCAT|CONCAT|LOWER|UPPER|UNIX_TIMESTAMP)\b/i)
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
      string: :string
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
