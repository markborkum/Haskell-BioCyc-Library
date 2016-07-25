require "active_support/core_ext/module/delegation"

module BioCyc # :nodoc:
  # A basic object
  class BasicObject
    include BioCyc::Processable

    # Default constructor
    #
    # @yieldparam instance [BioCyc::BasicObject]
    # @return [BioCyc::BasicObject]
    def initialize(&block)
      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end
  end

  # Base class for BioCyc objects with identifiers
  class Base < BioCyc::BasicObject
    def self.parse(node, &block) # :nodoc:
      orgid, frameid, detail = node.attribute("orgid").value, node.attribute("frameid").value, node.attribute("detail").value
      
      object_id = BioCyc::ObjectId.new(orgid, frameid)
      
      super(node, object_id, detail, &block)
    end

    attr_reader :object_id, :detail

    delegate :orgid, :frameid, to: :object_id

    # Default constructor
    #
    # @param object_id [BioCyc::ObjectId]
    # @param detail [#to_s]
    # @return [BioCyc::Base]
    # @yieldparam instance [BioCyc::Base]
    def initialize(object_id, detail, &block)
      @object_id, @detail = object_id, detail
      
      super(&block)
    end
  end

  module CML # :nodoc:
    class Molecule < BioCyc::BasicObject # :nodoc:
      attr :id, xpath: "@id"
      attr :title, xpath: "@title"
      attr :formal_charge, xpath: "@formalCharge", type: :integer, default: 0
      attr :formula, xpath: "formula/@concise"
      attr :molecular_weight, xpath: "float[@title = 'molecularWeight']/text()", type: :float_with_units
      attr :smiles, xpath: "string[@title = 'smiles']/text()"
      
      attr :atoms, xpath: "atomArray/atom", type: "BioCyc::CML::Atom", collection: true
      attr :bonds, xpath: "bondArray/bond", type: "BioCyc::CML::Bond", collection: true
    end

    class Atom < BioCyc::BasicObject # :nodoc:
      attr :id, xpath: "@id"
      attr :element_type, xpath: "@elementType"
      attr :formal_charge, xpath: "@formalCharge", type: :integer, default: 0
      attr :x2, xpath: "@x2", type: :float
      attr :y2, xpath: "@y2", type: :float
    end

    class Bond < BioCyc::BasicObject # :nodoc:
      attr :id, xpath: "@id"
      attr :atom_refs, xpath: "@atomRefs", default: "" do |s| s.to_s.split(/\s+/) end
      attr :order, xpath: "@order", type: :integer
    end
  end

  class Cofactor < BioCyc::BasicObject # :nodoc:
    has_one :citation, xpath: "citation/Publication"
    has_one :compound, xpath: "Compound"
  end

  class Complex < BioCyc::Base # :nodoc:
    # TODO
  end

  class Component < BioCyc::BasicObject # :nodoc:
    attr :coefficient, xpath: "coefficient[@datatype = 'integer']/text()", type: :integer, default: 1

    has_one :citation, xpath: "citation/Publication"
    has_one :protein, xpath: "Protein"
  end

  class Compound < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Compound"
    has_many :parent, xpath: "parent/Compound"

    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :gibbs_0, xpath: "gibbs-0[@datatype = 'float']/text()", type: :float_with_units
    attr :inchi, xpath: "inchi[@datatype = 'string']/text()"
    attr :inchi_key, xpath: "inchi-key[@datatype = 'string']/text()"
    attr :molecular_weight, xpath: "molecular-weight[@datatype = 'float']/text()", type: :float_with_units

    has_many :appears_in_left_side_of, xpath: "appears-in-left-side-of/Reaction"
    has_many :appears_in_right_side_of, xpath: "appears-in-right-side-of/Reaction"
    attr :cml_molecule, xpath: "cml/molecule", type: "BioCyc::CML::Molecule"
    attr :dblink, xpath: "dblink", type: "BioCyc::DbLink", collection: true
    has_many :regulates, xpath: "regulates/Regulation"
  end

  class Created < BioCyc::BasicObject # :nodoc:
    attr :date, xpath: "date[@datatype = 'date']/text()", type: :date

    has_one :organization, xpath: "Organization"
    has_one :person, xpath: "Person"
  end

  class Credits < BioCyc::BasicObject # :nodoc:
    attr :created, xpath: "created", type: "BioCyc::Created"
    attr :last_curated, xpath: "last-curated", type: "BioCyc::LastCurated"
  end

  class DbLink < BioCyc::BasicObject # :nodoc:
    attr :db, xpath: "dblink-db/text()"
    attr :oid, xpath: "dblink-oid/text()"
    attr :relationship, xpath: "dblink-relationship/text()"
    attr :url, xpath: "dblink-url/text() | dblink-URL/text()"
  end

  class DNABindingSite < BioCyc::Base # :nodoc:
    # TODO
  end

  class ECNumber < BioCyc::BasicObject # :nodoc:
    attr :value, xpath: "text()"
    attr :official, xpath: "official/text()"
  end

  class EnzymaticReaction < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__

    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :physiologically_relevant, xpath: "physiologically-relevant[@datatype = 'boolean']/text()", type: :boolean, default: false
    alias_method :physiologically_relevant?, :physiologically_relevant

    attr :cofactor, xpath: "cofactor", type: "BioCyc::Cofactor", collection: true
    has_many :enzyme, xpath: "enzyme/Protein"
    attr :evidence, xpath: "evidence", type: "BioCyc::Evidence", collection: true
    attr :km, xpath: "km", type: "BioCyc::Km"
    attr :reaction_direction, xpath: "reaction-direction", type: "BioCyc::ReactionDirection"
    has_many :reaction, xpath: "reaction/Reaction"
    has_many :regulated_by, xpath: "regulated-by/Regulation"
  end

  class Evidence < BioCyc::BasicObject # :nodoc:
    attr :with, xpath: "with[@datatype = 'string']/text()"

    has_one :evidence_code, xpath: "Evidence-Code"
    has_one :publication, xpath: "Publication"
  end

  class EvidenceCode < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Evidence-Code"
    has_one :parent, xpath: "parent/Evidence-Code"

    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
  end

  class Feature < BioCyc::Base # :nodoc:
    # TODO
  end

  class Gene < BioCyc::Base # :nodoc:
    # TODO
  end

  class GeneticElement < BioCyc::Base # :nodoc:
    # TODO
  end

  class GOTerm < BioCyc::Base # :nodoc:
    # TODO
  end

  class Km < BioCyc::BasicObject # :nodoc:
    attr :value, xpath: "value/text()", type: :integer_with_units

    has_one :citation, xpath: "citation/Publication"
    has_one :substrate, xpath: "substrate/Compound"
  end

  class LastCurated < BioCyc::BasicObject # :nodoc:
    attr :date, xpath: "date[@datatype = 'date']/text()", type: :date

    has_one :organization, xpath: "Organization"
    has_one :person, xpath: "Person"
  end

  class Left < BioCyc::BasicObject # :nodoc:
    attr :coefficient, xpath: "coefficient[@datatype = 'integer']/text()", type: :integer, default: 1

    has_one :object, xpath: "Compound | Protein | RNA"
  end

  class MolecularWeightExp < BioCyc::BasicObject # :nodoc:
    attr :value, xpath: "text()", type: :float_with_units

    has_one :citation, xpath: "citation/Publication"
  end

  class MRNABindingSite < BioCyc::Base # :nodoc:
    # TODO
  end

  class Organism < BioCyc::Base # :nodoc:
    # TODO
  end

  class Organization < BioCyc::Base # :nodoc:
    attr :abbrev_name, xpath: "abbrev-name[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :email, xpath: "email[@datatype = 'string']/text()"
    attr :url, xpath: "url[@datatype = 'string']/text()"
  end

  class Pathway < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Pathway"
    has_many :parent, xpath: "parent/Pathway"

    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    has_many :citation, xpath: "citation/Publication"
    attr :credits, xpath: "credits", type: "BioCyc::Credits"
    attr :evidence, xpath: "evidence", type: "BioCyc::Evidence", collection: true
    has_many :in_pathway, xpath: "in-pathway/Pathway"
    attr :reaction_layout, xpath: "reaction-layout", type: "BioCyc::ReactionLayout", collection: true
    has_many :reaction_list, xpath: "reaction-list/*"
    attr :reaction_ordering, xpath: "reaction-ordering", type: "BioCyc::ReactionOrdering", collection: true
    has_many :sub_pathway, xpath: "sub-pathway/Pathway"
    has_many :super_pathway, xpath: "super-pathway/Pathway"
  end

  class Person < BioCyc::Base # :nodoc:
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :email, xpath: "email[@datatype = 'string']/text()"

    has_many :affiliations, xpath: "affiliations/Organization"
  end

  class Pi < BioCyc::BasicObject # :nodoc:
    attr :value, xpath: "text()", type: :float_with_units

    has_one :citation, xpath: "citation/Publication"
  end

  class Protein < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Protein"
    has_many :parent, xpath: "parent/Protein"

    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :molecular_weight_exp, xpath: "molecular-weight-exp[@datatype = 'float']", type: "BioCyc::MolecularWeightExp"

    has_many :catalyzes, xpath: "catalyzes/Enzymatic-Reaction"
    has_many :citation, xpath: "citation/Publication"
    has_many :component_of, xpath: "component-of/Protein"
    attr :component, xpath: "component", type: "BioCyc::Component", collection: true
    attr :credits, xpath: "credits", type: "BioCyc::Credits"
    attr :dblink, xpath: "dblink", type: "BioCyc::DbLink", collection: true
    has_many :has_feature, xpath: "has-feature/Feature"
    has_many :gene, xpath: "gene/Gene"
    attr :pi, xpath: "pi[@datatype = 'float']", type: "BioCyc::Pi"

    # TODO "has-go-term"

    # TODO "location"
  end

  class Promoter < BioCyc::Base # :nodoc:
    # TODO
  end

  class Publication < BioCyc::Base # :nodoc:
    attr :author, xpath: "author[@datatype = 'string']/text()", collection: true
    attr :pubmed_id, xpath: "pubmed-id[@datatype = 'string']/text()"
    attr :source, xpath: "source[@datatype = 'string']/text()"
    attr :title, xpath: "title[@datatype = 'string']/text()"
    attr :year, xpath: "year[@datatype = 'integer']/text()", type: :integer
  end

  class Reaction < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Reaction"
    has_many :parent, xpath: "parent/Reaction"

    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :physiologically_relevant, xpath: "physiologically-relevant[@datatype = 'boolean']/text()", type: :boolean, default: false
    alias_method :physiologically_relevant?, :physiologically_relevant

    attr :ec_number, xpath: "ec-number", type: "BioCyc::ECNumber"
    has_many :enzymatic_reaction, xpath: "enzymatic-reaction/Enzymatic-Reaction"
    has_many :in_pathway, xpath: "in-pathway/Pathway"
    attr :left, xpath: "left", type: "BioCyc::Left", collection: true
    attr :reaction_direction, xpath: "reaction-direction", type: "BioCyc::ReactionDirection"
    attr :right, xpath: "right", type: "BioCyc::Right", collection: true

    # Returns the BioCyc atom mappings for this reaction
    #
    # @return [Array<Hash{String=>String}>]
    # @see [BioCyc::AtomMappings]
    def atom_mappings
      @atom_mappings ||= BioCyc.download_atom_mappings(orgid, frameid)
    end
  end

  class ReactionDirection < BioCyc::BasicObject # :nodoc:
    attr :value, xpath: "text()"

    has_one :citation, xpath: "citation/Publication"
  end

  class ReactionLayout < BioCyc::BasicObject # :nodoc:
    attr :direction, xpath: "direction/text()"

    has_many :left_primaries, xpath: "left-primaries/*"
    has_one :object, xpath: "Reaction | Pathway"
    has_many :right_primaries, xpath: "right-primaries/*"
  end

  class ReactionOrdering < BioCyc::BasicObject # :nodoc:
    has_many :predecessor_reactions, xpath: "predecessor-reactions/Reaction"
    has_one :reaction, xpath: "Reaction"
  end

  class Regulation < BioCyc::Base # :nodoc:
    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Reaction"
    has_many :parent, xpath: "parent/Reaction"

    attr :comment, xpath: "comment[@datatype = 'string']/text()"

    attr :mode, xpath: "mode[@datatype = 'string']/text()"
    attr :physiologically_relevant, xpath: "physiologically-relevant[@datatype = 'boolean']/text()", type: :boolean, default: false
    alias_method :physiologically_relevant?, :physiologically_relevant

    has_one :citation, xpath: "citation/Publication"
    has_one :regulated_entity, xpath: "regulated-entity/Enzymatic-Reaction"
    has_one :regulator, xpath: "regulator/Compound"
  end

  class Right < BioCyc::BasicObject # :nodoc:
    attr :coefficient, xpath: "coefficient[@datatype = 'integer']/text()", type: :integer, default: 1

    has_one :object, xpath: "Compound | Protein | RNA"
  end

  class RNA < BioCyc::Base # :nodoc:
    # TODO
  end

  class Terminator < BioCyc::Base # :nodoc:
    # TODO
  end

  class TranscriptionUnit < BioCyc::Base # :nodoc:
    # TODO
  end
end
