module BioCyc # :nodoc:
  class BioCycError < StandardError # :nodoc:
  end

  class ObjectInvalid < BioCycError # :nodoc:
    attr_reader :model, :name, :node
    
    def initialize(message = nil, model = nil, name = nil, node = nil)
      @model, @name, @node = model, name, node
      
      super(message)
    end
  end

  class ObjectIdInvalid < BioCycError # :nodoc:
    attr_reader :id

    def initialize(message = nil, id = nil)
      @id = id
      
      super(message)
    end
  end

  class ObjectNotFound < BioCycError # :nodoc:
    attr_reader :orgid, :frameid, :detail

    def initialize(message = nil, orgid = nil, frameid = nil, detail = nil)
      @orgid, @frameid, @detail = orgid, frameid, detail
      
      super(message)
    end
  end
end
