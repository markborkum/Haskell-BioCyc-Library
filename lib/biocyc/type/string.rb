module BioCyc # :nodoc:
  module Type # :nodoc:
    class String # :nodoc:
      def type # :nodoc:
        :string
      end
      
      def cast(node) # :nodoc:
        return nil if node.nil?
        
        case node.node_type
          when Nokogiri::XML::Node::ATTRIBUTE_NODE then node.value.try(:strip)
          when Nokogiri::XML::Node::TEXT_NODE then node.text.try(:strip)
          when Nokogiri::XML::Node::CDATA_SECTION_NODE then node.text.try(:strip)
          else raise ArgumentError, "Invalid node type #{node.node_type.inspect}"
        end
      end
    end
  end
end
