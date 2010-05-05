class RnaSeqRefGenome < ActiveRecord::Base

  # return a string suitable for injecting into a <select> element (or for use with select_tag()) describing all the reference genomes.  
  def self.all_as_select_options
    find(:all).map{ |refg| 
      selected=' selected=1'
      o="<option value='#{refg.id}'#{selected}>#{refg.description}</option>"
      selected=''
      o
    }.join("\n")
  end
end
