class Platform < ActiveRecord::Base
  has_many :instruments
  has_many :sample_prep_kits
  has_many :sample_mixtures

  def lane_number_options
    samples_per_flow_cell.split(/\s*,\s*/).collect{|n| n.to_i}
  end
end
