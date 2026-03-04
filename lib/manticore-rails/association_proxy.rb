# frozen_string_literal: true

module ManticoreClient
  module Rails
    class AssociationProxy
      def initialize(*parts)
        @parts = parts.map(&:to_s)
      end

      def method_missing(name, *args)
        if args.any?
          # transcript(:approved_text) → "transcript(approved_text)"
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
end
