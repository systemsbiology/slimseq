class SequencingRun < ActiveRecord::Base
  belongs_to :flow_cell
  belongs_to :instrument
  
  after_create :mark_flow_cell_as_sequenced
  before_destroy :mark_flow_cell_as_clustered
   
  def date_yymmdd
    date.strftime("%y%m%d")
  end
  
  def run_name
    "#{date_yymmdd}_" +
    "#{instrument.serial_number}_#{flow_cell.name}"
  end
  
private

  def mark_flow_cell_as_sequenced
    flow_cell.sequence!
  end
  
  def mark_flow_cell_as_clustered
    flow_cell.unsequence!
  end

end
