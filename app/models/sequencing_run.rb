class SequencingRun < ActiveRecord::Base
  named_scope :best, :conditions => {:best => true}
  
  belongs_to :flow_cell
  belongs_to :instrument
  has_many :pipeline_results
  
  before_create :set_best_run
  after_create :mark_flow_cell_as_sequenced
  before_destroy :mark_flow_cell_as_clustered
   
  def date_yymmdd
    date.strftime("%y%m%d")
  end
  
  def run_name
    "#{date_yymmdd}_" +
    "#{instrument.serial_number}_#{flow_cell.prefixed_name}"
  end

  def update_attributes(attributes)  
    # handle a change in the best sequencing run
    if(attributes[:best] == "1" || attributes[:best] == true)
      sequencing_runs = SequencingRun.find(:all, :conditions => {:flow_cell_id => flow_cell_id})
      
      # only applies when there are 2+ sequencing runs per flow cell
      if(sequencing_runs.size > 1)
        sequencing_runs.each do |run|
          run.update_attribute('best', false)
        end
      end
    end
    
    super(attributes)
  end

  def self.find_by_run_name(run_name)
    sequencing_run = nil

    name_match = run_name.match(/^(\d{6})_(.*)_FC(.*)$/)
    if(name_match)
      date = Date.strptime(name_match[1],"%y%m%d")
      instrument = name_match[2]
      flow_cell = name_match[3]

      sequencing_run = SequencingRun.find(:first, :include => [:flow_cell, :instrument],
        :conditions => ["date = ? AND flow_cells.name = ? AND instruments.serial_number = ?",
          date, flow_cell, instrument]
      )
    end
    
    return sequencing_run
  end  
  
private

  def set_best_run
    sequencing_runs = SequencingRun.find(:all, :conditions => {:flow_cell_id => flow_cell_id})
  
    # only necessary if other runs exist
    if(sequencing_runs.size > 0)
      sequencing_runs.each do |run|
        run.update_attribute('best', false)
      end
    end
  end
  
  def mark_flow_cell_as_sequenced
    flow_cell.sequence!
  end
  
  def mark_flow_cell_as_clustered
    # only "unsequence" the flow cell if it has no other attached sequencing runs
    if(flow_cell.sequencing_runs.size == 1)
      flow_cell.unsequence!
    end
  end

end
