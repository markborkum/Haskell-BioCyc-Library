require "biocyc/errors"
require "biocyc/object_id"

module BioCyc # :nodoc:
  module Processors # :nodoc:
    module Builder # :nodoc:
      class BelongsTo < Processor
        self.valid_options += [
          :css, :xpath,
          :collection, :null,
        ]

        self.default_options = self.default_options.merge({
          collection: false,
          null: true,
        })

        def build(&block) # :nodoc:
          super
          
          collection = options[:collection]
          default_foreign_key = send(:default_foreign_key)
          default_instance = send(:default_instance)
          instance_variable_name = send(:instance_variable_name)
          instance_variable_name_for_foreign_key = send(:instance_variable_name_for_foreign_key)
          reader_method_name = send(:reader_method_name)
          reader_method_name_for_foreign_key = send(:reader_method_name_for_foreign_key)
          writer_method_name = send(:writer_method_name)
          writer_method_name_for_foreign_key = send(:writer_method_name_for_foreign_key)
          
          model.instance_eval do
            define_method(reader_method_name) do ||
              if instance_variable_defined?(instance_variable_name)
                instance_variable_get(instance_variable_name)
              elsif instance_variable_defined?(instance_variable_name_for_foreign_key)
                foreign_key = instance_variable_get(instance_variable_name_for_foreign_key)
                
                instance = collection ? foreign_key.collect { |object_id| object_id.to_object(&block) } : foreign_key.to_object(&block)
                
                send(writer_method_name, instance)
              else
                default_instance
              end
            end
            
            define_method(writer_method_name) do |instance|
              remove_instance_variable(instance_variable_name_for_foreign_key) if instance_variable_defined?(instance_variable_name_for_foreign_key)
              
              instance_variable_set(instance_variable_name, instance)
            end
            
            define_method(reader_method_name_for_foreign_key) do ||
              if instance_variable_defined?(instance_variable_name_for_foreign_key)
                instance_variable_get(instance_variable_name_for_foreign_key)
              elsif instance_variable_defined?(instance_variable_name)
                instance = instance_variable_get(instance_variable_name)
                
                collection ? instance.collect(&:object_id) : instance.object_id
              else
                default_foreign_key
              end
            end
            
            define_method(writer_method_name_for_foreign_key) do |foreign_key|
              remove_instance_variable(instance_variable_name) if instance_variable_defined?(instance_variable_name)
              
              instance_variable_set(instance_variable_name_for_foreign_key, foreign_key)
            end
          end
          
          return self
        end

        def call(instance, node) # :nodoc:
          object_ids = node_set_for(node).collect { |child_node| cast(child_node) }
          
          foreign_key = begin
            if object_ids.empty?
              if options[:null]
                default_foreign_key
              else
                raise BioCyc::ObjectInvalid.new("Object is invalid", model, name, node)
              end
            else
              options[:collection] ? object_ids : object_ids.first
            end
          end
          
          instance.send(writer_method_name_for_foreign_key, foreign_key)
          
          return
        end

        private

        def cast(node) # :nodoc:
          orgid, frameid = node.attribute("orgid").value, node.attribute("frameid").value
          
          BioCyc::ObjectId.new(orgid, frameid)
        end

        def default_foreign_key # :nodoc:
          options[:collection] ? Array.new : nil
        end

        def default_instance # :nodoc:
          options[:collection] ? Array.new : nil
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

        def instance_variable_name # :nodoc:
          :"@#{reader_method_name}"
        end

        def instance_variable_name_for_foreign_key # :nodoc:
          :"@#{reader_method_name_for_foreign_key}"
        end

        def reader_method_name # :nodoc:
          :"#{name}"
        end

        def reader_method_name_for_foreign_key # :nodoc:
          :"#{reader_method_name}_id#{options[:collection] ? "s" : ""}"
        end

        def writer_method_name # :nodoc:
          :"#{reader_method_name}="
        end

        def writer_method_name_for_foreign_key # :nodoc:
          :"#{reader_method_name_for_foreign_key}="
        end
      end
    end
  end
end
