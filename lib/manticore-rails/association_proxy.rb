# frozen_string_literal: true

module ManticoreRails
  # Proxy object that builds dot-notation association paths in the
  # {IndexBuilder} DSL. Each method call appends a segment, producing
  # strings like +"tags.name"+ or +"author.company.name"+.
  #
  # @example In an index definition
  #   define_manticore_index do
  #     indexes tags.name          # => "tags.name"
  #     indexes author.company.name # => "author.company.name"
  #   end
  class AssociationProxy
    def initialize(*parts)
      @parts = parts.map(&:to_s)
    end

    # Appends a segment to the path. If called with arguments, produces
    # a SQL function string (e.g. +"transcript.approved_text(lang)"+).
    # Without arguments, returns a new proxy with the appended segment.
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

    # The dot-notation path as a string.
    # @return [String]
    def to_s
      @parts.join(".")
    end

    # Implicit string coercion, allowing the proxy to be used where
    # Ruby expects a String (e.g. string interpolation, hash keys).
    # @return [String]
    def to_str
      to_s
    end
  end
end
