class PipelineResult < ActiveRecord::Base
  belongs_to :sequencing_run
  belongs_to :flow_cell_lane
  has_many :post_pipeline

  # should only have one result per combination of sequencing run, flow cell lane and 
  # date gerald was run
  validates_uniqueness_of :base_directory, :scope => [
    :sequencing_run_id, :flow_cell_lane_id, :gerald_date
  ]
  validates_presence_of :base_directory, :eland_output_file, :summary_file
  
  def after_create
    # mark the flow cell lane as complete
    flow_cell_lane = FlowCellLane.find(flow_cell_lane_id)
    flow_cell_lane.complete!

    # try to record the run summary information
    import_run_summary
  end

  def after_save
    flow_cell_lane.reload.update_attributes(:updated_at => Time.now)
  end

  def import_run_summary
    # isolate exceptions since we don't want to crash the pipeline results
    # import process
    begin
      require 'nokogiri'

      doc = Nokogiri::Slop( open(summary_file) )
      
      run_yield = doc.xpath("/html/body/table[2]/tr[2]/td[3]").first.content
      sequencing_run.update_attributes(:yield_kb => run_yield)
      doc.xpath("/html/body/table[4]/tr").each do |tr|
        # skip header and footer rows
        if( tr.xpath(".//td").first.content.match(/\A\d/) )
          lane = tr.xpath(".//td").first.content
          yield_kb = tr.xpath(".//td")[1].content
          clusters = tr.xpath(".//td")[2].content.match(/\A(\d+) /)[1]
          pass = tr.xpath(".//td")[6].content.match(/\A(\d+\.\d+) /)[1]
          align = tr.xpath(".//td")[7].content.match(/\A(\d+\.\d+) /)[1]
          error = tr.xpath(".//td")[9].content.match(/\A(\d+\.\d+) /)[1]

          lane = FlowCellLane.find(:first, :conditions => {
            :flow_cell_id => sequencing_run.flow_cell_id,
            :lane_number => lane
          } )

          if(lane)
            lane.update_attributes(
              :lane_yield_kb => yield_kb,
              :average_clusters => clusters,
              :percent_pass_filter_clusters => pass,
              :percent_align => align,
              :percent_error => error
            )
            lane.save
          end
        end
      end
    rescue StandardError => e
      logger.error "Run summary import error: #{e.to_s}\n"
    end
  end
end
