require "active_support/core_ext/object/try"

module BioCyc # :nodoc:
  module Type # :nodoc:
    class Float < String # :nodoc:
      def type # :nodoc:
        :float
      end

      def cast(node) # :nodoc:
        super(node).try(:to_f)
      end
    end
  end
end
