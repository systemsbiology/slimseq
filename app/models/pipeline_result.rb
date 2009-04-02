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
    flow_cell_lane = FlowCellLane.find(flow_cell_lane_id)
    flow_cell_lane.complete!

    # try to record the run summary information
    import_run_summary
  end

  def import_run_summary
    # isolate exceptions since we don't want to crash the pipeline results
    # import process
    begin
      require 'nokogiri'

      doc = Nokogiri::Slop( open(summary_file) )
      
      run_yield = doc.xpath("/html/body/table[2]/tr[2]/td[3]").first.content
      sequencing_run.update_attributes(:yield_kb => run_yield)
    rescue

    end
  end
end
