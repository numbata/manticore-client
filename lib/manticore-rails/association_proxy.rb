# frozen_string_literal: true

module ManticoreRails
  # Builds dot-notation association paths in the IndexBuilder DSL.
  # Each method call appends a segment, e.g. tags.name => "tags.name".
  class AssociationProxy
    def initialize(*parts)
      @parts = parts.map(&:to_s)
    end

    def method_missing(name, *args)
      if args.any?
        "#{self}.#{name}(#{args.first})"
      else
        self.class.new(*@parts, name)
      end
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end

    def to_s
      @parts.join(".")
    end

    def to_str
      to_s
    end
  end
end
