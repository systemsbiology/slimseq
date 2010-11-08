class Platform < ActiveRecord::Base
  has_many :instruments
  has_many :sample_prep_kits
  has_many :sample_mixtures

  named_scope :flow_cell_and_sequencing_separate, :conditions => {:flow_cell_and_sequencing_separate => true}
  named_scope :flow_cell_and_sequencing_combined, :conditions => {:flow_cell_and_sequencing_separate => false}

  def lane_number_options
    samples_per_flow_cell.split(/\s*,\s*/).collect{|n| n.to_i}
  end
end
