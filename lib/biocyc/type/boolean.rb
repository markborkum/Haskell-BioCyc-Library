module BioCyc # :nodoc:
  module Type # :nodoc:
    class Boolean < String # :nodoc:
      def type # :nodoc:
        :boolean
      end

      def cast(node) # :nodoc:
        "true".eql?(super(node))
      end
    end
  end
end
