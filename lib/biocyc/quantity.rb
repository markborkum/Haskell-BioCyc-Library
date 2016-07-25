module BioCyc # :nodoc:
  # A dimensioned quantity
  class Quantity
    attr_reader :quantity, :units

    # Default constructor
    #
    # @param quantity [Object]
    # @param units [String]
    def initialize(quantity, units = nil)
      @quantity, @units = quantity, units
    end

    def ==(other) # :nodoc:
      return false unless other.is_a?(BioCyc::Quantity)
      
      (quantity == other.quantity) && (units == other.units)
    end
    alias_method :eql?, :==

    def hash # :nodoc:
      quantity.hash ^ units.hash
    end

    def to_s # :nodoc:
      [quantity, units].compact.collect(&:to_s).join(" ")
    end
  end
end
