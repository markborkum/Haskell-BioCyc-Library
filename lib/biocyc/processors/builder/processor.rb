require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/keys"

module BioCyc # :nodoc:
  module Processors # :nodoc:
    module Builder # :nodoc:
      # A processor
      class Processor
        # Valid options
        #
        # @return [Array<Symbol>]
        class_attribute :valid_options
        self.valid_options = []

        # Default options
        #
        # @return [Hash{Symbol=>Object}]
        class_attribute :default_options
        self.default_options = {}

        attr_reader :model, :name, :options

        # Build an instance of this class
        #
        # @param model [Class]
        # @param name [String]
        # @param options [Hash{Symbol=>Object}]
        # @return [BioCyc::Processors::Builder::Processor]
        # @yieldparam value [Object]
        def self.build(model, name, options = {}, &block)
          new(model, name, options).build(&block)
        end

        # Default constructor
        #
        # @param model [Class]
        # @param name [String]
        # @param options [Hash{Symbol=>Object}]
        # @return [BioCyc::Processors::Builder::Processor]
        def initialize(model, name, options = {})
          @model, @name, @options = model, name, self.class.default_options.merge(options)
        end

        # Build this instance
        #
        # @return [BioCyc::Processors::Builder::Processor]
        # @yieldparam value [Object]
        def build(&block)
          validate_options
          register!
          return self
        end

        # Call this instance
        #
        # @param instance [Object]
        # @param node [Nokogiri::XML::Node]
        # @raise [BioCyc::ObjectInvalid]
        # @return [NilClass]
        def call(instance, node)
          return
        end

        private

        def register! # :nodoc:
          model.processors[name] = self
        end

        # def unregister! # :nodoc:
        #   model.processors.delete(name)
        # end

        def validate_options # :nodoc:
          options.assert_valid_keys(self.class.valid_options)
        end
      end
    end
  end
end
