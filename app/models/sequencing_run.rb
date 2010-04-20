class SequencingRun < ActiveRecord::Base
  named_scope :best, :conditions => {:best => true}
  
  belongs_to :flow_cell
  belongs_to :instrument
  has_many :pipeline_results
  
  validates_presence_of :flow_cell_id

  before_create :set_best_run
  after_create :mark_flow_cell_as_sequenced
  before_destroy :mark_flow_cell_as_clustered
   
  def date_yymmdd
    date.strftime("%y%m%d")
  end
  
  def run_name
    if run_number
      [date_yymmdd, instrument.serial_number, "%04d" % run_number, flow_cell.prefixed_name].join("_")
    else
      [date_yymmdd, instrument.serial_number, flow_cell.prefixed_name].join("_")
    end
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

    name_match = run_name.match(/^(\d{6})_(.*?)_(\d{4})*_*FC(.*)$/)
    if(name_match)
      date = Date.strptime(name_match[1],"%y%m%d")
      instrument = name_match[2]
      run_number = name_match[3]
      flow_cell = name_match[4]

      sequencing_run = SequencingRun.find(:first, :include => [:flow_cell, :instrument],
        :conditions => ["date = ? AND flow_cells.name = ? AND instruments.serial_number = ?",
          date, flow_cell, instrument]
      )
    end
    
    return sequencing_run
  end  
  
  def write_config_file(params)
    gerald_defaults = GeraldDefaults.find(:first)
    
    file_name = "tmp/txt/#{run_name}-config.txt"
    
    file = File.new(file_name, "w")
    
    file << "#{gerald_defaults.header}\n"
    file << "EMAIL_LIST #{gerald_defaults.email_list}\n"
    file << "EMAIL_SERVER #{gerald_defaults.email_server}\n"
    file << "EMAIL_DOMAIN #{gerald_defaults.email_domain}\n"
    file << "WEB_DIR_ROOT #{instrument.web_root}\n"
    params.keys.sort.each do |i|
      hash = params[i]
      file << "#{hash[:lane_number]}:ANALYSIS #{hash[:analysis]}\n"
      file << "#{hash[:lane_number]}:ELAND_GENOME #{hash[:eland_genome]}\n"
      file << "#{hash[:lane_number]}:ELAND_SEED_LENGTH #{hash[:eland_seed_length]}\n"
      file << "#{hash[:lane_number]}:ELAND_MAX_MATCHES #{hash[:eland_max_matches]}\n"
      file << "#{hash[:lane_number]}:USE_BASES #{hash[:use_bases]}\n"
    end
    
    file.close
  end
  
  def default_gerald_params
    gerald_defaults = GeraldDefaults.find(:first)

    gerald_params = Hash.new

    lane_counter = 0
    flow_cell.flow_cell_lanes.each do |lane|
      sample_mixture = lane.sample_mixture

      gerald_params[lane_counter.to_s] = {
        :lane_number => lane.lane_number,
        :analysis => sample_mixture.sample_prep_kit.eland_analysis,
        #FIXME: Update gerald config generation w/ multiplexing support
        :eland_genome => sample_mixture.samples.first.reference_genome.fasta_path,
        :eland_seed_length => sample_mixture.eland_seed_length,
        :eland_max_matches => sample_mixture.eland_max_matches,
        :use_bases => lane.use_bases_string(gerald_defaults.skip_last_base)
      }
      lane_counter += 1
    end
    
    return gerald_params
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
