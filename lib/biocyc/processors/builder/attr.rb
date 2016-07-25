require "active_support/inflector"

module BioCyc # :nodoc:
  module Processors # :nodoc:
    module Builder # :nodoc:
      class Attr < Processor
        self.valid_options += [
          :css, :xpath,
          :default,
          :collection, :null, :type,
        ]

        self.default_options = self.default_options.merge({
          collection: false,
          null: true,
          type: :string,
        })

        def build(&block) # :nodoc:
          super
          model.send(:attr_accessor, name)
          @block = block || Proc.new { |value| value }
          return self
        end

        def call(instance, node) # :nodoc:
          objects = node_set_for(node).collect { |child_node| cast(child_node) }
          
          value = begin
            if objects.empty?
              if options[:null]
                default_value
              else
                raise BioCyc::ObjectInvalid.new("Object is invalid", model, name, node)
              end
            else
              options[:collection] ? objects : objects.first
            end
          end
          
          value = @block.call(value)
          
          instance.send(writer_method_name, value)
          
          return
        end

        private

        def cast(node) # :nodoc:
          type = options[:type]
          
          case type
            when Class, Module then type.parse(node)
            when String then type.constantize.parse(node)
            when Symbol then BioCyc::Type.lookup(type).cast(node)
            else raise ArgumentError, "Unknown type #{type.inspect}"
          end
        end

        def default_value # :nodoc:
          options.key?(:default) ? options[:default] : (options[:collection] ? Array.new : nil)
        end

        def node_set_for(node) # :nodoc:
          if !(css = options[:css]).nil?
            node.css(css)
          elsif !(xpath = options[:xpath]).nil?
            node.xpath(xpath)
          else
            [node]
          end
        end

        def reader_method_name # :nodoc:
          :"#{name}"
        end

        def writer_method_name # :nodoc:
          :"#{reader_method_name}="
        end
      end
    end
  end
end
