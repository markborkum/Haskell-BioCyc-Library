require "open-uri"
require "zlib"

module BioCyc # :nodoc:
  # BioCyc Object-Id retrieval
  # 
  # @param orgid [String] the identifier for the organism database, e.g., ECOLI, META, AFER243159
  # @param frameid [String] the BioCyc identifier for the object, e.g., ARGSYN-PWY, EG11025, FRUCTOSE-6P
  # @param detail [Symbol] indicates whether the returned output should contain no detail, low detail or full detail for the requested object
  # @raise [URI::InvalidURIError] if the URI is invalid
  # @return [Nokogiri::XML::Document]
  # @see http://biocyc.org/web-services.shtml#R2
  def self.getxml(orgid, frameid, detail = nil)
    if detail.nil?
      uri_string = "http://websvc.biocyc.org/getxml?%s:%s" % [orgid, frameid]
    else
      uri_string = "http://websvc.biocyc.org/getxml?id=%s:%s&detail=%s" % [orgid, frameid, detail]
    end
    
    uri = URI.parse(uri_string)
    
    uri.open { |io|
      data = Zlib::GzipReader.new(io).read
      
      Nokogiri::XML(data)
    }
  end

  # Retrieving a Set of Objects Using the Pathway Tools API Functions
  # 
  # @param api_function [String] API function name
  # @param orgid [String] the identifier for the organism database, e.g., ECOLI, META, AFER243159
  # @param frameid [String] the BioCyc identifier for the object, e.g., ARGSYN-PWY, EG11025, FRUCTOSE-6P
  # @param detail [Symbol] indicates whether the returned output should contain no detail, low detail or full detail for the requested object
  # @raise [URI::InvalidURIError] if the URI is invalid
  # @return [Nokogiri::XML::Document]
  # @see http://biocyc.org/web-services.shtml#R8
  def self.apixml(api_function, orgid, frameid, detail = nil)
    if detail.nil?
      uri_string = "http://websvc.biocyc.org/apixml?fn=%s&id=%s:%s" % [api_function, orgid, frameid]
    else
      uri_string = "http://websvc.biocyc.org/apixml?fn=%s&id=%s:%s&detail=%s" % [api_function, orgid, frameid, detail]
    end
    
    uri = URI.parse(uri_string)
    
    uri.open { |io|
      data = Zlib::GzipReader.new(io).read
      
      Nokogiri::XML(data)
    }
  end

  # Retrieving the Set of Objects Returned by a BioVelo Query
  # 
  # @param query [String] BioVelo query
  # @param detail [Symbol] indicates whether the returned output should contain no detail, low detail or full detail for the requested object
  # @raise [URI::InvalidURIError] if the URI is invalid
  # @return [Nokogiri::XML::Document]
  # @see http://biocyc.org/web-services.shtml#R9
  def self.xmlquery(query, detail = nil)
    if detail.nil?
      uri_string = "http://websvc.biocyc.org/xmlquery?%s" % [query]
    else
      uri_string = "http://websvc.biocyc.org/xmlquery?query=%s&detail=%s" % [query, detail]
    end
    
    uri = URI.parse(uri_string)
    
    uri.open { |io|
      data = Zlib::GzipReader.new(io).read
      
      Nokogiri::XML(data)
    }
  end

  # Data Retrieval Web Services
  #
  # @param orgid [String] the identifier for the organism database, e.g. ECOLI, META, AFER243159
  # @param pathway [String] the BioCyc identifier for the pathway, e.g. GLYCOLYSIS, ARGSYN-PWY, PWY0-1299
  # @param type [String] specifies whether data should use BioPAX Level 2 or Level 3
  # @raise [URI::InvalidURIError] if the URI is invalid
  # @return [RDF::Graph]
  # @see http://biocyc.org/web-services.shtml#R4
  def self.pathway_biopax(orgid, pathway, type = nil)
    if type.nil?
      uri_string = "http://websvc.biocyc.org/%s/pathway-biopax?object=%s" % [orgid, pathway]
    else
      uri_string = "http://websvc.biocyc.org/%s/pathway-biopax?type=%s&object=%s" % [orgid, type, pathway]
    end

    uri = URI.parse(uri_string)

    uri.open { |io|
      data = Zlib::GzipReader.new(io).read

      RDF::Graph.new { |graph|
        graph << RDF::Reader.for(:rdfxml).new(data)
      }
    }
  end
end
