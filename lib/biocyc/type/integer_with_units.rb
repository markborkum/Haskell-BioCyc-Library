require "active_support/core_ext/object/try"

require "biocyc/quantity"

module BioCyc # :nodoc:
  module Type # :nodoc:
    class IntegerWithUnits < Integer # :nodoc:
      def type # :nodoc:
        :integer_with_units
      end

      def cast(node) # :nodoc:
        quantity = super(node)
        return nil if quantity.nil?
        units = node.parent.attribute("units").try(:value)
        BioCyc::Quantity.new(quantity, units)
      end
    end
  end
end
