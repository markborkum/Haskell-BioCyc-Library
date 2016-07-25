require "active_support/core_ext/object/try"

require "biocyc/quantity"

module BioCyc # :nodoc:
  module Type # :nodoc:
    class FloatWithUnits < Float # :nodoc:
      def type # :nodoc:
        :float_with_units
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
