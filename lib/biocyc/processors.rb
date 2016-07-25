require "active_support/cache"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/inflector"

require "biocyc/errors"
require "biocyc/object_id"
require "biocyc/processors/builder/processor"
require "biocyc/processors/builder/attr"
require "biocyc/processors/builder/belongs_to"
require "biocyc/web_services"

module BioCyc # :nodoc:
  # Mixin for dereferenceable types (must provide `#orgid` and `#frameid` methods)
  module Dereferenceable
    def self.included(klass) # :nodoc:
      klass.send(:extend, BioCyc::Dereferenceable::ClassMethods)
      klass.send(:include, BioCyc::Dereferenceable::InstanceMethods)
      return
    end
    
    module ClassMethods # :nodoc:
      # Cache of dereferenced objects
      #
      # @return [ActiveSupport::Cache]
      def objects
        class_variable_set(:@@object_cache, ActiveSupport::Cache.lookup_store(:memory_store)) unless class_variable_defined?(:@@object_cache)
        class_variable_get(:@@object_cache)
      end
    end
    
    module InstanceMethods # :nodoc:
      # Returns a cache key for this instance
      #
      # @param detail [String]
      # @return [String]
      def to_cache_key(detail = nil)
        ActiveSupport::Cache.expand_cache_key([orgid, frameid, detail].compact, "object")
      end

      # Dereferences this instance, caches and returns the result
      #
      # @param detail [String]
      # @raise [BioCyc::ObjectNotFound]
      # @return [BioCyc::Processable]
      def to_object(detail = nil, &block)
        cache = self.class.objects
        
        cache_key = to_cache_key(detail)
        
        if cache.exist?(cache_key)
          cache.fetch(cache_key)
        else
          doc = BioCyc.getxml(detail.nil? ? unescape(orgid) : escape(orgid), detail.nil? ? unescape(frameid) : escape(frameid), detail)
          
          if !(node = doc.xpath("/ptools-xml/*[@orgid = '#{unescape(orgid)}' and @frameid = '#{unescape(frameid)}'][1]").first).nil? && !node.name.eql?("Error")
            klass = "BioCyc::#{node.name.gsub("-", "").classify}".constantize
          
            object = klass.parse(node, &block)
          
            cache.write(cache_key, object)
          
            object
          else
            raise BioCyc::ObjectNotFound.new("BioCyc object not found #{orgid}:#{frameid}#{detail.nil? ? "" : " (#{detail.inspect})"}", orgid, frameid, detail)
          end
        end
      end

      private

      # Escape unsafe characters with codes
      #
      # @param s [#to_s]
      # @return String
      def escape(s)
        s.to_s.gsub("+", "%2B")
      end

      # Unescape unsafe characters with codes
      #
      # @param s [#to_s]
      # @return String
      def unescape(s)
        s.to_s.gsub(/%2[Bb]/, "+")
      end
    end
  end

  # Mixin for processable types
  module Processable
    def self.included(klass) # :nodoc:
      klass.send(:extend, BioCyc::Processable::ClassMethods)
      klass.send(:include, BioCyc::Processable::InstanceMethods)
      return
    end

    module ClassMethods # :nodoc:
      # Cache of processors
      #
      # @return [Hash{String=>BioCyc::Processors::Builder::Processor}]
      def processors
        class_variable_set(:@@processor_cache, HashWithIndifferentAccess.new) unless class_variable_defined?(:@@processor_cache)
        class_variable_get(:@@processor_cache)
      end

      # Parse an XML node
      #
      # @param node [Nokogiri::XML::Node]
      # @param args [Array<Object>]
      # @return [BioCyc::Processable]
      # @yieldparam instance [BioCyc::Processable]
      def parse(node, *args, &block)
        new(*args) do |instance|
          processors.each do |name, processor|
            processor.call(instance, node)
          end
          
          if block_given?
            case block.arity
              when 1 then block.call(instance)
              else instance.instance_eval(&block)
            end
          end
        end
      end

      # Build an attribute
      #
      # @param name [String]
      # @param options [Hash{Symbol=>Object}]
      # @return [BioCyc::Processors::Builder::Attr]
      # @yieldparam value [Object]
      def attr(name, options = {}, &block)
        BioCyc::Processors::Builder::Attr.build(self, name, options, &block)
      end

      # Build a "belongs to" relationship
      #
      # @param name [String]
      # @param options [Hash{Symbol=>Object}]
      # @return [BioCyc::Processors::Builder::BelongsTo]
      # @yieldparam value [Object]
      def belongs_to(name, options = {}, &block)
        BioCyc::Processors::Builder::BelongsTo.build(self, name, options, &block)
      end

      def has_one(name, options = {}, &block) # :nodoc:
        belongs_to(name, options.merge(collection: false), &block)
      end

      def has_many(name, options = {}, &block) # :nodoc:
        belongs_to(name, options.merge(collection: true), &block)
      end
    end

    module InstanceMethods # :nodoc:
    end
  end
end

BioCyc::ObjectId.send(:include, BioCyc::Dereferenceable)
