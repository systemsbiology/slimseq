class PipelineResult < ActiveRecord::Base
  belongs_to :sequencing_run
  belongs_to :flow_cell_lane
  
  # should only have one result per combination of sequencing run, flow cell lane and 
  # date gerald was run
  validates_uniqueness_of :base_directory, :scope => [
    :sequencing_run_id, :flow_cell_lane_id, :gerald_date
  ]
  
  def after_create
    # mark the flow cell lane as complete
    flow_cell_lane.complete!
  end
end
