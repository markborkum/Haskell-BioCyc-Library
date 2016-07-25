#!/usr/bin/env ruby

require 'biocyc'

###
# Escherichia coli K-12 substr. MG1655
# Reaction: 4.2.1.2
#
# ECOLI:FUMHYDR-RXN
#
# @see http://biocyc.org/ECOLI/NEW-IMAGE?type=REACTION-IN-PATHWAY&object=FUMHYDR-RXN
# @see http://biocyc.org/getxml?id=ECOLI:FUMHYDR-RXN&detail=full

###
# Create a new object identifier.
object_id = BioCyc::ObjectId.for("ECOLI:FUMHYDR-RXN")

###
# Print object identifier.
puts object_id.inspect

###
# Download atom mappings and construct corresponding object.
atom_mappings = BioCyc.download_atom_mappings(object_id.orgid, object_id.frameid)

###
# Print object.
puts atom_mappings.inspect
