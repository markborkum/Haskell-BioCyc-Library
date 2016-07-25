require "active_support/core_ext/module/delegation"

require "biocyc/atom_mappings"
require "biocyc/object_id"
require "biocyc/processors"

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

  # An object with an identifier
  class Object < BioCyc::BasicObject
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
    # @return [BioCyc::Object]
    # @yieldparam instance [BioCyc::Object]
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

  class Cco < BioCyc::Object # :nodoc:
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component, xpath: "component", type: "BioCyc::Ext::Component", collection: true
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :definition, xpath: "definition[@datatype = 'string']/text()"
    attr :goid, xpath: "goid[@datatype = 'string']/text()"
    has_many :sensu, xpath: "sensu/Organism"
    has_many :surrounded_by, xpath: "surrounded-by/cco"
    has_many :surrounds, xpath: "surrounds/cco"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/cco"
    has_many :parent, xpath: "parent/cco"
    has_many :subclass, xpath: "subclass/cco"
  end

  class Compound < BioCyc::Object # :nodoc:
    attr :abbrev_name, xpath: "abbrev-name[@datatype = 'string']/text()"
    has_many :appears_in_left_side_of, xpath: "appears-in-left-side-of/Reaction"
    has_many :appears_in_right_side_of, xpath: "appears-in-right-side-of/Reaction"
    has_many :citation, xpath: "citation/Publication"
    attr :cml, xpath: "cml", type: "BioCyc::Ext::CML"
    has_many :cofactors_of, xpath: "cofactors-of/Enzymatic-Reaction"
    has_many :cofactors_or_prosthetic_groups_of, xpath: "cofactors-or-prosthetic-groups-of/Enzymatic-Reaction"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :credits, xpath: "credits", type: "BioCyc::Ext::Credits"
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    attr :gibbs_0, xpath: "gibbs-0", type: "BioCyc::Ext::Gibbs0"
    attr :inchi, xpath: "inchi[@datatype = 'string']/text()"
    attr :inchi_key, xpath: "inchi-key[@datatype = 'string']/text()"
    attr :molecular_weight, xpath: "molecular-weight[@datatype = 'float']/text()", type: :float_with_units
    attr :n_1_name, xpath: "n-1-name[@datatype = 'string']/text()"
    attr :n_name, xpath: "n-name[@datatype = 'string']/text()"
    attr :n_plus_1_name, xpath: "n-plus-1-name[@datatype = 'string']/text()"
    attr :pka1, xpath: "pka1[@datatype = 'float']/text()", type: :float
    attr :pka2, xpath: "pka2[@datatype = 'float']/text()", type: :float
    attr :pka3, xpath: "pka3[@datatype = 'float']/text()", type: :float
    has_many :prosthetic_groups_of, xpath: "prosthetic-groups-of/Enzymatic-Reaction"
    has_many :regulates, xpath: "regulates/Reaction"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    attr :systematic_name, xpath: "systematic-name[@datatype = 'string']/text()"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Compound"
    has_many :parent, xpath: "parent/Compound"
    has_many :subclass, xpath: "subclass/Compound"
  end

  class DNABindingSite < BioCyc::Object # :nodoc:
    attr :abs_center_pos, xpath: "abs-center-pos[@datatype = 'float']/text()", type: :float
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    has_many :involved_in_regulation, xpath: "involved-in-regulation/Regulation"
    attr :site_length, xpath: "site-length[@datatype = 'integer']/text()", type: :integer
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
  end

  class EnzymaticReaction < BioCyc::Object # :nodoc:
    attr :alternative_cofactor, xpath: "alternative-cofactor", type: "BioCyc::Ext::AlternativeCofactor", collection: true
    attr :alternative_substrate, xpath: "alternative-substrate", type: "BioCyc::Ext::AlternativeSubstrate", collection: true
    has_many :citation, xpath: "citation/Publication"
    attr :cofactor, xpath: "cofactor", type: "BioCyc::Ext::Cofactor", collection: true
    attr :cofactor_binding_comment, xpath: "cofactor-binding-comment[@datatype = 'string']/text()", collection: true
    attr :cofactor_or_prosthetic_group, xpath: "cofactor-or-prosthetic-group", type: "BioCyc::Ext::CofactorOrProstheticGroup", collection: true
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    has_many :enzyme, xpath: "enzyme/Protein"
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    attr :km, xpath: "km", type: "BioCyc::Ext::Km", collection: true
    attr :ph_opt, xpath: "ph-opt", type: "BioCyc::Ext::PhOpt"
    attr :prosthetic_group, xpath: "prosthetic-group", type: "BioCyc::Ext::ProstheticGroup", collection: true
    attr :physiologically_relevant, xpath: "physiologically-relevant[@datatype = 'boolean']/text()", type: :boolean, default: false
    alias_method :physiologically_relevant?, :physiologically_relevant
    has_many :reaction, xpath: "reaction/Reaction"
    attr :reaction_direction, xpath: "reaction-direction", type: "BioCyc::Ext::ReactionDirection"
    has_many :regulated_by, xpath: "regulated-by/Regulation"
    has_many :required_protein_complex, xpath: "required-protein-complex/Protein"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    attr :temperature_opt, xpath: "temperature-opt", type: "BioCyc::Ext::TemperatureOpt"
  end

  class EvidenceCode < BioCyc::Object # :nodoc:
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :parent, xpath: "parent/Evidence-Code"
  end

  class Feature < BioCyc::Object # :nodoc:
    attr :alternate_sequence, xpath: "alternate-sequence[@datatype = 'string']/text()"
    has_many :attached_group, xpath: "attached-group/Compound"
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    has_many :feature_of, xpath: "feature-of/Protein"
    attr :homology_motif, xpath: "homology-motif[@datatype = 'string']/text()"
    attr :left_end_position, xpath: "left-end-position[@datatype = 'integer']/text()", type: :integer
    attr :residue_number, xpath: "residue-number[@datatype = 'integer']/text()", type: :integer
    has_many :residue_type, xpath: "residue-type/Compound"
    attr :right_end_position, xpath: "right-end-position[@datatype = 'integer']/text()", type: :integer

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :parent, xpath: "parent/Feature"
  end

  class GOTerm < BioCyc::Object # :nodoc:
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :definition, xpath: "definition[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    has_many :term_members, xpath: "term-members/Protein"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :subclass, xpath: "subclass/GO-Term"
  end

  class Gene < BioCyc::Object # :nodoc:
    attr :accession_1, xpath: "accession-1[@datatype = 'string']/text()"
    attr :accession_2, xpath: "accession-2[@datatype = 'string']/text()"
    attr :centisome_position, xpath: "centisome-position[@datatype = 'float']/text()", type: :float_with_units
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component, xpath: "component", type: "BioCyc::Ext::Component", collection: true
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    attr :interrupted, xpath: "interrupted[@datatype = 'boolean']/text()", type: :boolean
    alias_method :interrupted?, :interrupted
    attr :left_end_position, xpath: "left-end-position[@datatype = 'integer']/text()", type: :integer
    has_many :product, xpath: "product/Protein"
    attr :right_end_position, xpath: "right-end-position[@datatype = 'integer']/text()", type: :integer
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    attr :transcription_direction, xpath: "transcription-direction[@datatype = 'string']/text()"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Gene"
    has_many :parent, xpath: "parent/Gene"
    has_many :subclass, xpath: "subclass/Gene"
  end

  class GeneticElement < BioCyc::Object # :nodoc:
    attr :circular, xpath: "circular[@datatype = 'boolean']/text()", type: :boolean
    alias_method :circular?, :circular
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component, xpath: "component", type: "BioCyc::Ext::Component", collection: true
    attr :sequence_length, xpath: "sequence-length[@datatype = 'integer']", type: :integer

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Genetic-Element"
    has_many :parent, xpath: "parent/Genetic-Element"
    has_many :subclass, xpath: "subclass/Genetic-Element"
  end

  class MRNABindingSite < BioCyc::Object # :nodoc:
    has_many :involved_in_regulation, xpath: "involved-in-regulation/Regulation"
    attr :left_end_position, xpath: "left-end-position[@datatype = 'integer']/text()", type: :integer
    attr :right_end_position, xpath: "right-end-position[@datatype = 'integer']/text()", type: :integer
  end

  class Organism < BioCyc::Object # :nodoc:
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    has_many :genome, xpath: "genome/Genetic-Element"
    has_many :pgdb_author, xpath: "pgdb-author/Person"
    attr :pgdb_copyright, xpath: "pgdb-copyright[@datatype = 'string']/text()"
    attr :pgdb_footer_citation, xpath: "pgdb-footer-citation[@datatype = 'string']/text()"
    attr :pgdb_home_page, xpath: "pgdb-home-page[@datatype = 'string']/text()"
    attr :pgdb_name, xpath: "pgdb-name[@datatype = 'string']/text()"
    attr :pgdb_tier, xpath: "pgdb-tier[@datatype = 'integer']/text()", type: :integer
    attr :rank, xpath: "rank/text()"
    attr :strain_name, xpath: "strain-name[@datatype = 'string']/text()"
    attr :subspecies_name, xpath: "subspecies-name[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :parent, xpath: "parent/Organism"
  end

  class Organization < BioCyc::Object # :nodoc:
    attr :abbrev_name, xpath: "abbrev-name[@datatype = 'string']/text()"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :email, xpath: "email[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    attr :url, xpath: "url[@datatype = 'string']/text()"
  end

  class Pathway < BioCyc::Object # :nodoc:
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :credits, xpath: "credits", type: "BioCyc::Ext::Credits"
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    has_many :enzymes_not_used, xpath: "enzymes-not-used/Protein"
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    has_many :hypothetical_reactions, xpath: "hypothetical-reactions/Reaction"
    has_many :in_pathway, xpath: "in-pathway/Pathway | in-pathway/Reaction"
    attr :pathway_link, xpath: "pathway-link", type: "BioCyc::Ext::PathwayLink", collection: true
    attr :reaction_layout, xpath: "reaction-layout", type: "BioCyc::Ext::ReactionLayout", collection: true
    has_many :reaction_list, xpath: "reaction-list/Pathway | reaction-list/Reaction"
    attr :reaction_ordering, xpath: "reaction-ordering", type: "BioCyc::Ext::ReactionOrdering", collection: true
    has_many :species, xpath: "species/Organism"
    has_many :sub_pathways, xpath: "sub-pathways/Pathway"
    has_many :super_pathways, xpath: "super-pathways/Pathway"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    has_many :taxonomic_range, xpath: "taxonomic-range/Organism"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Pathway"
    has_many :parent, xpath: "parent/Pathway"
    has_many :subclass, xpath: "subclass/Pathway"
  end

  class Person < BioCyc::Object # :nodoc:
    has_many :affiliations, xpath: "affiliations/Organization"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :email, xpath: "email[@datatype = 'string']/text()"
    attr :middle_name, xpath: "middle-name[@datatype = 'string']/text()"
  end

  class Promoter < BioCyc::Object # :nodoc:
    attr :absolute_plus_1_pos, xpath: "absolute-plus-1-pos[@datatype = 'integer']/text()", type: :integer_with_units
    has_many :binds_sigma_factor, xpath: "binds-sigma-factor/Protein"
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    attr :minus_10_left, xpath: "minus-10-left[@datatype = 'integer']/text()", type: :integer
    attr :minus_10_right, xpath: "minus-10-right[@datatype = 'integer']/text()", type: :integer
    attr :minus_35_left, xpath: "minus-35-left[@datatype = 'integer']/text()", type: :integer
    attr :minus_35_right, xpath: "minus-35-right[@datatype = 'integer']/text()", type: :integer
    has_many :regulated_by, xpath: "regulated-by/Regulation"
    attr :transcription_direction, xpath: "transcription-direction[@datatype = 'string']/text()"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
  end

  class Protein < BioCyc::Object # :nodoc:
    attr :abbrev_name, xpath: "abbrev-name[@datatype = 'string']/text()"
    has_many :appears_in_left_side_of, xpath: "appears-in-left-side-of/Reaction"
    has_many :appears_in_right_side_of, xpath: "appears-in-right-side-of/Reaction"
    has_many :catalyzes, xpath: "catalyzes/Enzymatic-Reaction"
    has_many :citation, xpath: "citation/Publication"
    attr :cml, xpath: "cml", type: "BioCyc::Ext::CML"
    has_many :cofactors_of, xpath: "cofactors-of/Enzymatic-Reaction"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component, xpath: "component", type: "BioCyc::Ext::Component", collection: true
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :consensus_sequence, xpath: "consensus-sequence[@datatype = 'string']/text()"
    attr :credits, xpath: "credits", type: "BioCyc::Ext::Credits"
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    attr :dna_sequence_size, xpath: "dna-sequence-size[@datatype = 'integer']/text()", type: :integer_with_units
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    attr :gene, xpath: "gene", type: "BioCyc::Ext::Gene", collection: true
    attr :has_feature, xpath: "has-feature", type: "BioCyc::Ext::HasFeature", collection: true
    attr :has_go_term, xpath: "has-go-term", type: "BioCyc::Ext::HasGOTerm", collection: true
    attr :intron_or_removed_segment, xpath: "intron-or-removed-segment", type: "BioCyc::Ext::IntronOrRemovedSegment", collection: true
    attr :isozyme_sequence_similarity, xpath: "isozyme-sequence-similarity", type: "BioCyc::Ext::IsozymeSequenceSimilarity", collection: true
    attr :location, xpath: "location", type: "BioCyc::Ext::Location", collection: true
    has_many :modified_form, xpath: "modified-form/Protein"
    attr :molecular_weight_exp, xpath: "molecular-weight-exp", type: "BioCyc::Ext::MolecularWeightExp"
    attr :molecular_weight_seq, xpath: "molecular-weight-seq", type: "BioCyc::Ext::MolecularWeightSeq"
    attr :pi, xpath: "pi", type: "BioCyc::Ext::Pi"
    has_many :prosthetic_groups_of, xpath: "prosthetic-groups-of/Enzymatic-Reaction"
    has_many :regulated_by, xpath: "regulated-by/Regulation"
    has_many :regulates, xpath: "regulates/Regulation"
    has_many :species, xpath: "species/Organism"
    attr :symmetry, xpath: "symettry/text()" # TODO
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    has_many :unmodified_form, xpath: "unmodified-form/Protein"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Protein"
    has_many :parent, xpath: "parent/Protein"
    has_many :subclass, xpath: "subclass/Protein"
  end

  class Publication < BioCyc::Object # :nodoc:
    attr :abstract, xpath: "abstract[@datatype = 'string']/text()"
    attr :agricola_id, xpath: "agricola-id[@datatype = 'string']/text()"
    attr :author, xpath: "author[@datatype = 'string']/text()", collection: true
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :doi_id, xpath: "doi-id[@datatype = 'string']/text()"
    attr :pubmed_id, xpath: "pubmed-id[@datatype = 'string']/text()"
    attr :source, xpath: "source[@datatype = 'string']/text()"
    attr :title, xpath: "title[@datatype = 'string']/text()"
    attr :url, xpath: "url[@datatype = 'string']/text()"
    attr :year, xpath: "year[@datatype = 'integer']/text()", type: :integer
  end

  class RNA < BioCyc::Object # :nodoc:
    has_many :appears_in_left_side_of, xpath: "appears-in-left-side-of/Reaction"
    has_many :appears_in_right_side_of, xpath: "appears-in-right-side-of/Reaction"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :credits, xpath: "credits", type: "BioCyc::Ext::Credits"
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    attr :gene, xpath: "gene", type: "BioCyc::Ext::Gene", collection: true
    attr :has_go_term, xpath: "has-go-term", type: "BioCyc::Ext::HasGOTerm", collection: true
    attr :n_1_name, xpath: "n-1-name[@datatype = 'string']/text()"
    attr :n_name, xpath: "n-name[@datatype = 'string']/text()"
    attr :n_plus_1_name, xpath: "n-plus-1-name[@datatype = 'string']/text()"
    has_many :regulates, xpath: "regulates/Regulation"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/RNA"
  end

  class Reaction < BioCyc::Object # :nodoc:
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :credits, xpath: "credits", type: "BioCyc::Ext::Credits"
    attr :dblink, xpath: "dblink", type: "BioCyc::Ext::Dblink", collection: true
    attr :deltag0, xpath: "deltag0[@datatype = 'float']", type: "BioCyc::Ext::DeltaG0"
    attr :ec_number, xpath: "ec-number", type: "BioCyc::Ext::ECNumber", collection: true
    has_many :enzymatic_reaction, xpath: "enzymatic-reaction/Enzymatic-Reaction"
    has_many :enzymes_not_used, xpath: "enzymes-not-used/Protein"
    has_many :in_pathway, xpath: "in-pathway/Pathway | in-pathway/Reaction"
    attr :left, xpath: "left", type: "BioCyc::Ext::Left", collection: true
    attr :official_ec, xpath: "official-ec[@datatype = 'boolean']/text()", type: :boolean
    alias_method :official_ec?, :official_ec
    attr :orphan, xpath: "orphan/text()" # TODO
    attr :physiologically_relevant, xpath: "physiologically-relevant[@datatype = 'boolean']/text()", type: :boolean, default: false
    alias_method :physiologically_relevant?, :physiologically_relevant
    attr :reaction_direction, xpath: "reaction-direction", type: "BioCyc::Ext::ReactionDirection"
    has_many :reaction_list, xpath: "reaction-list/Pathway | reaction-list/Reaction"
    attr :reaction_ordering, xpath: "reaction-ordering", type: "BioCyc::Ext::ReactionOrdering", collection: true
    has_many :regulated_by, xpath: "regulated-by/Regulation"
    attr :requirements, xpath: "requirements", type: "BioCyc::Ext::Requirements", collection: true
    attr :right, xpath: "right", type: "BioCyc::Ext::Right", collection: true
    has_many :signal, xpath: "signal/Compound"
    has_many :species, xpath: "species/Organism"
    attr :spontaneous, xpath: "spontaneous[@datatype = 'boolean']/text()", type: :boolean
    alias_method :spontaneous?, :spontaneous
    attr :std_reduction_potential, xpath: "std-reduction-potential[@datatype = 'float']/text()", type: :float_with_units
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :instance, xpath: "instance/Reaction"
    has_many :parent, xpath: "parent/Reaction"
    has_many :subclass, xpath: "subclass/Reaction"

    # Returns the BioCyc atom mappings for this reaction
    #
    # @return [Array<Hash{String=>String}>]
    # @see [BioCyc::AtomMappings]
    def atom_mappings
      @atom_mappings ||= BioCyc.download_atom_mappings(orgid, frameid)
    end
  end

  class Regulation < BioCyc::Object # :nodoc:
    has_many :accessory_proteins, xpath: "accessory-proteins/Protein"
    has_many :associated_binding_site, xpath: "associated-binding-site/DNA-Binding-Site | associated-binding-site/MRNA-Binding-Site"
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :mechanism, xpath: "mechanism/text()" # TODO
    attr :mode, xpath: "mode[@datatype = 'string']/text()" # TODO
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    attr :pause_end_pos, xpath: "pause-end-pos[@datatype = 'integer']/text()", type: :integer
    attr :pause_start_pos, xpath: "pause-start-pos[@datatype = 'integer']/text()", type: :integer
    attr :physiologically_relevant, xpath: "physiologically-relevant[@datatype = 'boolean']/text()", type: :boolean, default: false
    alias_method :physiologically_relevant?, :physiologically_relevant
    has_many :regulated_entity, xpath: "regulated-entity/Enzymatic-Reaction | regulated-entity/Promoter | regulated-entity/Protein | regulated-entity/Reaction | regulated-entity/Terminator | regulated-entity/Transcription-Unit"
    has_many :regulator, xpath: "regulator/Compound | regulator/Protein | regulator/RNA"

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :parent, xpath: "parent/Regulation"
  end

  class Terminator < BioCyc::Object # :nodoc:
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :component_of, xpath: "component-of", type: "BioCyc::Ext::ComponentOf", collection: true
    attr :left_end_position, xpath: "left-end-position[@datatype = 'integer']/text()", type: :integer
    has_many :regulated_by, xpath: "regulated-by/Regulation"
    attr :right_end_position, xpath: "right-end-position[@datatype = 'integer']/text()", type: :integer

    attr :__class__, xpath: "@class", type: :boolean, default: false
    alias_method :class?, :__class__
    has_many :parent, xpath: "parent/Terminator"
  end

  class TranscriptionUnit < BioCyc::Object # :nodoc:
    has_many :citation, xpath: "citation/Publication"
    attr :comment, xpath: "comment[@datatype = 'string']/text()"
    attr :common_name, xpath: "common-name[@datatype = 'string']/text()"
    attr :component, xpath: "component", type: "BioCyc::Ext::Component", collection: true
    attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
    attr :extent_unknown, xpath: "extent-unknown[@datatype = 'boolean']/text()", type: :boolean
    has_many :regulated_by, xpath: "regulated-by/Regulation"
    attr :synonym, xpath: "synonym[@datatype = 'string']/text()", collection: true
    attr :transcription_direction, xpath: "transcription-direction[@datatype = 'string']/text()"
  end

  module Ext # :nodoc:
    class AlternativeCofactor < BioCyc::BasicObject # :nodoc:
      has_many :alternate, xpath: "alternate/Compound | alternate/Protein | alternate/RNA"
      has_many :citation, xpath: "citation/Publication"
      attr :cofactor, xpath: "cofactor", type: "BioCyc::Ext::Cofactor", collection: true
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
    end

    class AlternativeSubstrate < BioCyc::BasicObject # :nodoc:
      has_one :alternate, xpath: "alternate/Compound | alternate/Protein | alternate/RNA"
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :substrate, xpath: "substrate/Compound | substrate/Protein | substrate/RNA"
    end

    class CML < BioCyc::BasicObject # :nodoc:
      attr :molecule, xpath: "molecule", type: "BioCyc::CML::Molecule"
    end

    class Cofactor < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :value, xpath: "Compound | Protein" # TODO
    end

    class CofactorOrProstheticGroup < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :value, xpath: "Compound" # TODO
    end

    class Component < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :coefficient, xpath: "coefficient[@datatype = 'integer']/text()", type: :integer, default: 1
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :value, xpath: "cco | Compound | DNA-Binding-Site | Gene | Promoter | Protein | RNA | Terminator" # TODO
    end

    class ComponentOf < BioCyc::BasicObject # :nodoc:
      has_many :cco, xpath: "cco"
      has_one :gene, xpath: "Gene"
      has_many :genetic_element, xpath: "Genetic-Element"
      has_many :protein, xpath: "Protein"
      has_many :transcription_unit, xpath: "Transcription-Unit"
    end

    class Created < BioCyc::BasicObject # :nodoc:
      attr :date, xpath: "date[@datatype = 'date']/text()", type: :date
      has_many :organization, xpath: "Organization"
      has_many :person, xpath: "Person"
    end

    class Credits < BioCyc::BasicObject # :nodoc:
      attr :created, xpath: "created", type: "BioCyc::Ext::Created"
      attr :last_curated, xpath: "last-curated", type: "BioCyc::Ext::LastCurated"
      attr :nil, xpath: "nil", type: "BioCyc::Ext::Nil"
      attr :reviewed, xpath: "reviewed", type: "BioCyc::Ext::Reviewed"
      attr :revised, xpath: "reviewed", type: "BioCyc::Ext::Reviewed"
    end

    class Dblink < BioCyc::BasicObject # :nodoc:
      attr :db, xpath: "dblink-db/text()"
      attr :oid, xpath: "dblink-oid/text()"
      attr :relationship, xpath: "dblink-relationship/text()"
      attr :url, xpath: "dblink-url/text() | dblink-URL/text()"
    end

    class DeltaG0 < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      attr :value, xpath: "text()", type: :float_with_units
    end

    class ECNumber < BioCyc::BasicObject # :nodoc:
      attr :value, xpath: "text()"
      attr :official, xpath: "official/text()"
    end

    class Evidence < BioCyc::BasicObject # :nodoc:
      has_one :evidence_code, xpath: "Evidence-Code"
      has_one :publication, xpath: "Publication"
      attr :probability, xpath: "probability", type: "BioCyc::Ext::Probability"
      attr :with, xpath: "with[@datatype = 'string']/text()"
    end

    class Gene < BioCyc::BasicObject # :nodoc:
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :gene, xpath: "Gene"
    end

    class Gibbs0 < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :value, xpath: "text()", type: :float_with_units
    end

    class HasFeature < BioCyc::BasicObject # :nodoc:
      has_one :feature, xpath: "Feature"
      attr :state, xpath: "state/text()" # TODO
    end

    class HasGOTerm < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :evidence, xpath: "evidence", type: "BioCyc::Ext::Evidence", collection: true
      has_one :go_term, xpath: "GO-Term"
    end

    class IntronOrRemovedSegment < BioCyc::BasicObject # :nodoc:
      attr :end_bp, xpath: "end-bp[@datatype = 'integer']/text()", type: :integer
      attr :start_bp, xpath: "start-bp[@datatype = 'integer']/text()", type: :integer
    end

    class IsozymeSequenceSimilarity < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      attr :is_similar, xpath: "is-similar[@datatype = 'boolean']/text()", type: :boolean
      alias_method :is_similar?, :is_similar
      has_one :isozyme, xpath: "isozyme/Protein"
    end

    class Km < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_many :substrate, xpath: "substrate/Compound | substrate/Protein | substrate/RNA"
      attr :value, xpath: "value[@datatype = 'float']/text()", type: :float_with_units
    end

    class LastCurated < BioCyc::BasicObject # :nodoc:
      attr :date, xpath: "date[@datatype = 'date']/text()", type: :date
      has_many :organization, xpath: "Organization"
      has_many :person, xpath: "Person"
    end

    class Left < BioCyc::BasicObject # :nodoc:
      attr :coefficient, xpath: "coefficient[@datatype = 'integer']/text()", type: :integer, default: 1
      has_many :compartment, xpath: "compartment/cco"
      attr :name_slot, xpath: "name-slot/text()" # TODO
      has_one :value, xpath: "Compound | Protein | RNA"
    end

    class Location < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      has_one :cco, xpath: "cco"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
    end

    class MolecularWeightExp < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      attr :value, xpath: "text()", type: :float_with_units
    end

    class MolecularWeightSeq < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      attr :value, xpath: "text()", type: :float_with_units
    end

    class Nil < BioCyc::BasicObject # :nodoc:
      attr :date, xpath: "date[@datatype = 'date']/text()", type: :date
      has_many :organization, xpath: "Organization"
      has_many :person, xpath: "Person"
    end

    class PathwayLink < BioCyc::BasicObject # :nodoc:
      has_one :value, xpath: "Compound | Pathway | Protein"
      has_many :incoming_link_target, xpath: "incoming-link-target/Enzymatic-Reaction | incoming-link-target/Pathway | incoming-link-target/Protein | incoming-link-target/Reaction"
      has_many :link_target, xpath: "link-target/Enzymatic-Reaction | link-target/Pathway | link-target/Reaction"
      has_many :outgoing_link_target, xpath: "outgoing-link-target/Pathway"
    end

    class PhOpt < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      attr :value, xpath: "text()", type: :float_with_units
    end

    class Pi < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :value, xpath: "text()", type: :float_with_units
    end

    class Probability < BioCyc::BasicObject # :nodoc:
      has_many :evidence_code, xpath: "Evidence-Code"
      attr :value, xpath: "text()", type: :float_with_units # TODO
    end

    class ProstheticGroup < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :value, xpath: "Compound | Protein" # TODO
    end

    class ReactionDirection < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :value, xpath: "text()"
    end

    class ReactionLayout < BioCyc::BasicObject # :nodoc:
      attr :direction, xpath: "direction/text()"
      has_many :left_primaries, xpath: "left-primaries/Compound | left-primaries/Protein | left-primaries/RNA"
      has_many :right_primaries, xpath: "right-primaries/Compound | right-primaries/Protein | right-primaries/RNA"
      has_one :value, xpath: "Pathway | Reaction"
    end

    class ReactionOrdering < BioCyc::BasicObject # :nodoc:
      has_many :predecessor_reactions, xpath: "predecessor-reactions/Reaction"
      has_one :reaction, xpath: "Reaction"
    end

    class Requirements < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      has_one :compound, xpath: "Compound"
    end

    class Reviewed < BioCyc::BasicObject # :nodoc:
      attr :date, xpath: "date[@datatype = 'date']/text()", type: :date
      has_many :organization, xpath: "Organization"
      has_many :person, xpath: "Person"
    end

    class Revised < BioCyc::BasicObject # :nodoc:
      attr :date, xpath: "date[@datatype = 'date']/text()", type: :date
      has_many :organization, xpath: "Organization"
      has_many :person, xpath: "Person"
    end

    class Right < BioCyc::BasicObject # :nodoc:
      attr :coefficient, xpath: "coefficient[@datatype = 'integer']/text()", type: :integer, default: 1
      has_many :compartment, xpath: "compartment/cco"
      attr :name_slot, xpath: "name-slot/text()" # TODO
      has_one :value, xpath: "Compound | Protein | RNA"
    end

    class TemperatureOpt < BioCyc::BasicObject # :nodoc:
      has_many :citation, xpath: "citation/Publication"
      attr :comment, xpath: "comment[@datatype = 'string']/text()"
      attr :value, xpath: "text()", type: :float_with_units
    end
  end
end
