class DesiredRead < ActiveRecord::Base
  belongs_to :sample_mixture

  validates_numericality_of :alignment_start_position, :greater_than_or_equal_to => 1
  validates_numericality_of :alignment_end_position, :greater_than_or_equal_to => 1
  validates_presence_of :desired_read_length
end
