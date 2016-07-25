require "log4r"

require "biocyc/models"

# BioCyc Web Services
#
# @see http://biocyc.org/web-services.shtml
module BioCyc
  # Logger
  #
  # @return [Log4r::Logger]
  LOGGER = Log4r::Logger.new("BioCyc")
  LOGGER.outputters = Log4r::Outputter.stderr
end
