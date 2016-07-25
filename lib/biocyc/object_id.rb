require "biocyc/errors"

module BioCyc # :nodoc:
  # A BioCyc object identifier
  class ObjectId
    # Regular expression for BioCyc object identifiers
    #
    # @return [Regexp]
    ID_REGEXP = /\A((?:[A-Za-z0-9+-]|%[A-Fa-f0-9]{2})+):((?:[A-Za-z0-9+-]|%[A-Fa-f0-9]{2})+)\Z/.freeze
    
    # Returns a new instance of this class
    #
    # @param id [#to_s]
    # @raise [BioCyc::ObjectIdInvalid]
    # @return [BioCyc::ObjectId]
    def self.for(id)
      if !(md = ID_REGEXP.match(id.to_s)).nil?
        new(md[1], md[2])
      else
        raise BioCyc::ObjectIdInvalid.new("Invalid BioCyc object identifier #{id.inspect}", id)
      end
    end

    attr_reader :orgid, :frameid

    # Default constructor
    #
    # @param orgid [#to_s]
    # @param frameid [#to_s]
    # @return [BioCyc::ObjectId]
    def initialize(orgid, frameid)
      @orgid, @frameid = orgid, frameid
    end

    def ==(other) # :nodoc:
      return false unless other.is_a?(BioCyc::ObjectId)
      
      (orgid == other.orgid) && (frameid == other.frameid)
    end
    alias_method :eql?, :==

    def hash # :nodoc:
      orgid.hash ^ frameid.hash
    end

    def to_s # :nodoc:
      "#{orgid}:#{frameid}"
    end
  end
end
