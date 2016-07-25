require_relative "type/string"

require_relative "type/boolean"
require_relative "type/date"
require_relative "type/float"
require_relative "type/float_with_units"
require_relative "type/integer"
require_relative "type/integer_with_units"

module BioCyc # :nodoc:
  module Type # :nodoc:
    class Registry # :nodoc:
      def initialize # :nodoc:
        @registrations = Hash.new
      end

      # Register a type with a symbol
      #
      # @param symbol [Symbol]
      # @param type [BioCyc::Type::String]
      # @return [BioCyc::Type::Registry]
      def register(symbol, type)
        registrations[symbol] = type
        self
      end

      # Lookup a type with a symbol
      #
      # @param symbol [Symbol]
      # @raise [ArgumentError]
      # @return [BioCyc::Type::String]
      def lookup(symbol)
        if registrations.key?(symbol)
          registrations[symbol]
        else
          raise ArgumentError, "Unknown type #{symbol.inspect}"
        end
      end

      protected

      attr_reader :registrations
    end

    @registry = Registry.new

    class << self
      attr_accessor :registry

      delegate :register, :lookup, to: :registry
    end

    register(:boolean, Type::Boolean.new)
    register(:date, Type::Date.new)
    register(:float, Type::Float.new)
    register(:float_with_units, Type::FloatWithUnits.new)
    register(:integer, Type::Integer.new)
    register(:integer_with_units, Type::IntegerWithUnits.new)
    register(:string, Type::String.new)
  end
end
