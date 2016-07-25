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

    # Returns a string representation of this quantity
    #
    # @return [String]
    def to_s
      [quantity, units].compact.collect(&:to_s).join(" ")
    end
  end
end
