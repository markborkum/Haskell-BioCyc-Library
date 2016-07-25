Gem::Specification.new do |s|
  s.name        = "biocyc"
  s.version     = "0.0.0"
  s.date        = "2015-08-25"
  s.summary     = "BioCyc Database Collection"
  s.description = "A Ruby interface to the BioCyc Database Collection"
  s.authors     = ["Mark Borkum"]
  s.email       = "mark.borkum@pnnl.gov"
  s.files       = ["lib/biocyc.rb", "lib/biocyc/atom_mappings.rb", "lib/biocyc/errors.rb", "lib/biocyc/models.rb", "lib/biocyc/object_id.rb", "lib/biocyc/processors.rb", "lib/biocyc/processors/builder/attr.rb", "lib/biocyc/processors/builder/belongs_to.rb", "lib/biocyc/processors/builder/processor.rb", "lib/biocyc/quantity.rb", "lib/biocyc/type.rb", "lib/biocyc/type/boolean.rb", "lib/biocyc/type/date.rb", "lib/biocyc/type/float.rb", "lib/biocyc/type/float_with_units.rb", "lib/biocyc/type/integer.rb", "lib/biocyc/type/integer_with_units.rb", "lib/biocyc/type/string.rb", "lib/biocyc/web_services.rb"]
  s.homepage    = "http://rubygems.org/gems/biocyc"
  s.license     = "ECL-2.0"

  s.add_runtime_dependency "activesupport", [">= 4.2"]
  s.add_runtime_dependency "linkeddata", [">= 1.1"]
  s.add_runtime_dependency "nokogiri", [">= 1.6"]
end
