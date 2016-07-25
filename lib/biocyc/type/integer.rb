require "active_support/core_ext/object/try"

module BioCyc # :nodoc:
  module Type # :nodoc:
    class Integer < String # :nodoc:
      def type # :nodoc:
        :integer
      end

      def cast(node) # :nodoc:
        super(node).try(:to_i)
      end
    end
  end
end
