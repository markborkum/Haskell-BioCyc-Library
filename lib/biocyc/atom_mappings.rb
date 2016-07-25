require "open-uri"
require "zlib"

module BioCyc # :nodoc:
  # Reaction Atom Mappings
  #
  # @param orgid [String] the identifier for the organism database, e.g., ECOLI, META, AFER243159
  # @param frameid [String] the BioCyc identifier for the object, e.g., ARGSYN-PWY, EG11025, FRUCTOSE-6P
  # @raise [URI::InvalidURIError] if the URI is invalid
  # @return [Array<Hash{String=>String}>]
  # @see http://biocyc.org/PGDBConceptsGuide.shtml#node_sec_3.5.1
  def self.download_atom_mappings(orgid, frameid)
    uri_string = "http://biocyc.org/%s/download-atom-mappings?object=%s" % [orgid, frameid]
    
    uri = URI.parse(uri_string)
    
    uri.open { |io|
      data = Zlib::GzipReader.new(io).read
      
      BioCyc::AtomMappings.parse(data)
    }
  end

  module AtomMappings # :nodoc:
    module Regexen # :nodoc:
      ATOM_MAPPING = Regexp.new(%w{REACTION NTH-ATOM-MAPPING MAPPING-TYPE FROM-SIDE TO-SIDE INDICES}.collect { |s|
        Regexp.quote(s) + Regexp.quote(" - ") + "([^\n]+)" + "\n"
      }.join, Regexp::MULTILINE).freeze
      
      FROM_SIDE = Regexp.new(
        Regexp.quote("(") +
        "(" + Regexp.quote("(") + "[^" + Regexp.quote(")") + "]+" + Regexp.quote(")") + "|" + "[^\s]+" + ")" +
        "\s+" +
        "(0|[1-9][0-9]*)" +
        "\s+" +
        "(0|[1-9][0-9]*)" +
        Regexp.quote(")")
      ).freeze
      
      ID_WITH_INDEX = Regexp.new(Regexp.quote("(") + "([^\s]+)\s+(0|[1-9][0-9]*)" + Regexp.quote(")")).freeze
      
      INDEX = Regexp.new("0|[1-9][0-9]*").freeze
    end

    # Parse Atom Mappings
    #
    # @param s [String]
    # @return [Array<Hash{String=>String}>]
    def self.parse(s)
      s.to_s.scan(Regexen::ATOM_MAPPING).collect { |md|
        reaction, nth_atom_mapping, mapping_type, from_side, to_side, indices = *md
        
        from_side_acc = Array.new
        parse_from_side(from_side).each do |hash|
          Range.new(hash[:start_index], hash[:end_index]).to_a.each_with_index do |index, atom_id|
            from_side_acc << "#{hash[:index]}-#{hash[:id]}-atom#{atom_id + 1}"
          end
        end
        
        to_side_acc = Array.new
        parse_to_side(to_side).each do |hash|
          Range.new(hash[:start_index], hash[:end_index]).to_a.each_with_index do |index, atom_id|
            to_side_acc << "#{hash[:index]}-#{hash[:id]}-atom#{atom_id + 1}"
          end
        end
        
        result = Hash.new
        parse_indices(indices).each_with_index do |from_index, to_index|
          result[from_side_acc[from_index]] = to_side_acc[to_index]
        end
        result
      }
    end

    private

    # Parse "FROM-SIDE" component of an Atom Mapping
    #
    # @param s [String]
    # @return [Array<Hash{Symbol=>Object}>]
    def self.parse_from_side(s)
      # s.to_s.scan(Regexen::FROM_SIDE).collect { |md|
      #   id, start_index, end_index = *md
      #
      #   if !(md = id.to_s.match(Regexen::ID_WITH_INDEX)).nil?
      #     {
      #       id: md[1],
      #       index: md[2].to_i,
      #       start_index: start_index.to_i,
      #       end_index: end_index.to_i,
      #     }
      #   else
      #     {
      #       id: id,
      #       index: 1,
      #       start_index: start_index.to_i,
      #       end_index: end_index.to_i,
      #     }
      #   end
      # }
      
      records = s.to_s.scan(Regexen::FROM_SIDE).collect { |md|
        id, start_index, end_index = *md
        
        if !(md = id.to_s.match(Regexen::ID_WITH_INDEX)).nil?
          {
            id: md[1],
            start_index: start_index.to_i,
            end_index: end_index.to_i,
          }
        else
          {
            id: id,
            start_index: start_index.to_i,
            end_index: end_index.to_i,
          }
        end
      }
      
      id_to_count = Hash.new
      
      records.each do |record|
        id_to_count[record[:id]] ||= 0
        id_to_count[record[:id]] += 1
        
        record[:index] = id_to_count[record[:id]]
      end
      
      return records
    end

    # Parse "TO-SIDE" component of an Atom Mapping
    #
    # @param s [String]
    # @return [Array<Hash{Symbol=>Object}>]
    def self.parse_to_side(s)
      parse_from_side(s)
    end

    # Parse "INDICES" component of an Atom Mapping
    #
    # @param s [String]
    # @return [Array<Integer>]
    def self.parse_indices(s)
      s.to_s.scan(Regexen::INDEX).collect(&:to_i)
    end
  end
end
