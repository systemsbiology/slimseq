class SequencingRun < ActiveRecord::Base
  belongs_to :flow_cell
  belongs_to :instrument
  
  after_create :mark_flow_cell_as_sequenced
  before_destroy :mark_flow_cell_as_clustered
  
  def mark_flow_cell_as_sequenced
    flow_cell.sequence!
  end
  
  def mark_flow_cell_as_clustered
    flow_cell.unsequence!
  end
end
