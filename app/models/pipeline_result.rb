class PipelineResult < ActiveRecord::Base
  belongs_to :sequencing_run
  belongs_to :flow_cell_lane
  has_many :rnaseq_pipeline

  # should only have one result per combination of sequencing run, flow cell lane and 
  # date gerald was run
  validates_uniqueness_of :flow_cell_lane_id, :scope => [
    :sequencing_run_id, :gerald_date
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
      
      run_yield_description = doc.xpath("/html/body/table[2]/tr[1]/td[3]").first.content
      run_yield = doc.xpath("/html/body/table[2]/tr[2]/td[3]").first.content

      # handle some runs reporting Mbases instead of Kbases 
      run_yield = run_yield.to_i * 1000 if /.*Mbases.*/.match(run_yield_description)

      sequencing_run.update_attributes(:yield_kb => run_yield)

      doc.xpath("/html/body/table[4]/tr").each do |tr|
        # skip header and footer rows
        if( tr.xpath(".//td").first.content.match(/\A\d/) )
          lane = tr.xpath(".//td").first.content
          yield_kb = tr.xpath(".//td")[1].content
          clusters = match_integer( tr.xpath(".//td")[2].content )
          pass = match_float( tr.xpath(".//td")[6].content )
          align = match_float( tr.xpath(".//td")[7].content )
          error = match_float( tr.xpath(".//td")[9].content )

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

  private

  def match_integer(string)
    if string.match(/\A(\d+) /)
      return string.match(/\A(\d+) /)[1]
    else
      return "0"
    end
  end

  def match_float(string)
    if string.match(/\A(\d+\.\d+) /)
      return string.match(/\A(\d+\.\d+) /)[1]
    else
      return "0"
    end
  end
end
