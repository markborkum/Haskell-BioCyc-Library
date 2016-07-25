module BioCyc # :nodoc:
  # A BioCyc object identifier
  class ObjectId
    # Regular expression for BioCyc object identifiers
    #
    # @return [Regexp]
    ID_REGEXP = /\A((?:[A-Za-z0-9+-]|%[A-Fa-f0-9]{2})+):((?:[A-Za-z0-9+-]|%[A-Fa-f0-9]{2})+)\Z/.freeze
    
    # Returns a new instance of this class
    #
    # @param id [String]
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
      @orgid, @frameid = orgid.to_s.gsub("+", "%2B"), frameid.to_s.gsub("+", "%2B")
    end

    # Returns a string representation of this instance
    #
    # @return [String]
    def to_s
      "#{orgid}:#{frameid}"
    end
  end
end
