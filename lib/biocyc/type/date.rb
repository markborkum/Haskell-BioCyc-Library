module BioCyc # :nodoc:
  module Type # :nodoc:
    class Date < String # :nodoc:
      def type # :nodoc:
        :date
      end

      def cast(node) # :nodoc:
        string = super(node)
        return nil if string.nil?
        ::Date.strptime(string, "%Y-%m-%d")
      end
    end
  end
end
