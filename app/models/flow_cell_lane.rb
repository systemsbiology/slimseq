class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  belongs_to :sample_mixture
  
  has_many :pipeline_results
  
  validates_numericality_of :starting_concentration, :loaded_concentration

  after_create :mark_sample_mixture_as_clustered
  before_destroy :mark_sample_mixture_as_submitted

  acts_as_state_machine :initial => :clustered, :column => 'status'
  
  state :clustered, :after => [:unsequence_sample_mixture]
  state :sequenced, :after => [:sequence_sample_mixture]
  state :completed, :after => [:complete_sample_mixture_and_flow_cell]
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced    
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered
  end
  
  event :complete do
    transitions :from => :sequenced, :to => :completed    
  end

  def after_initialize
    if self.has_attribute?(:number_of_cycles) && number_of_cycles.nil? && sample_mixture
      self.number_of_cycles = sample_mixture.desired_read_length
    end
  end

  def mark_sample_mixture_as_clustered
    sample_mixture.cluster!
  end
  
  def mark_sample_mixture_as_submitted
    sample_mixture.unsequence!
    sample_mixture.uncluster!
  end
  
  def summary_hash
    return {
      :id => id,
      :flow_cell_uri => "#{SiteConfig.site_url}/flow_cells/#{flow_cell_id}",
      :lane_number => lane_number,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/flow_cell_lanes/#{id}"
    }
  end
  
  def detail_hash
    if(flow_cell.sequencing_runs.size == 0)
      sequencer_hash = {}
    else
      sequencing_run = flow_cell.sequencing_runs.best[0]
      sequencer_hash = {
        :name => sequencing_run.instrument.name,
        :serial_number => sequencing_run.instrument.serial_number,
        :instrument_version => sequencing_run.instrument.instrument_version
      }
    end
    
    return {
      :id => id,
      :flow_cell_uri => "#{SiteConfig.site_url}/flow_cells/#{flow_cell_id}",
      :flow_cell_name => flow_cell.prefixed_name,
      :lane_number => lane_number,
      :updated_at => updated_at,
      :starting_concentration => starting_concentration,
      :loaded_concentration => loaded_concentration,
      :raw_data_path => raw_data_path,
      :eland_output_file => eland_output_file,
      :summary_file => summary_file,
      :status => status,
      :comment => comment,
      :sequencer => sequencer_hash,
      :lane_yield_kb => lane_yield_kb,
      :average_clusters => average_clusters,
      :percent_pass_filter_clusters => percent_pass_filter_clusters,
      :percent_align => percent_align,
      :percent_error => percent_error,
      :sample_uris => sample_mixture.sample_ids.collect {|x|
        "#{SiteConfig.site_url}/samples/#{x}"
      }
    }
  end
  
  def raw_data_path
    if(pipeline_results.size > 0)
      return pipeline_results.find(:first, :order => "gerald_date DESC").base_directory
    end
  end
  
  def raw_data_path=(path)
    if(pipeline_results.size > 0)
      pipeline_results.find(:first, :order => "gerald_date DESC").
        update_attribute('base_directory', path)
    end
  end
  
  def eland_output_file
    if(pipeline_results.size > 0)
      return pipeline_results.find(:first, :order => "gerald_date DESC").eland_output_file
    end
  end

  def summary_file
    if(pipeline_results.size > 0)
      return pipeline_results.find(:first, :order => "gerald_date DESC").summary_file
    end
  end
  
  def default_result_path
    lab_group_profile = LabGroupProfile.find_by_lab_group_id(sample_mixture.project.lab_group_id)
    "#{SiteConfig.raw_data_root_path}/#{lab_group_profile.file_folder}/" +
    "#{sample_mixture.project.file_folder}/#{flow_cell.sequencing_runs.best[0].run_name}"
  end
  
  def use_bases_string(skip_last_base)
    # only use the alignment start and stop positions if the samples's desired read length
    # matches the lane's number of cycles
    if sample_mixture.desired_read_length == number_of_cycles
      alignment_start_position = sample_mixture.alignment_start_position
      alignment_end_position = sample_mixture.alignment_end_position
      desired_read_length = number_of_cycles
    else
      alignment_start_position = 1
      alignment_end_position = number_of_cycles
      desired_read_length = number_of_cycles
    end

    alignment_end_position = desired_read_length if alignment_end_position > desired_read_length

    s = ""

    # starting at the beginning
    if(alignment_start_position == 1)
      if(alignment_end_position == desired_read_length)
        s = "Y" * desired_read_length
      else
        s = "Y" * alignment_end_position + 
            "n" * (desired_read_length-alignment_end_position)
      end
    # or starting later than the beginning, but going to the end
    elsif(alignment_end_position == desired_read_length)
      s = "n" * (alignment_start_position-1) +
          "Y" * (desired_read_length-alignment_start_position+1)
    # or in the middle
    else
      s = "n" * (alignment_start_position-1) +
          "Y" * (alignment_end_position-alignment_start_position+1) +
          "n" * (desired_read_length-alignment_end_position)
    end

    s[-1] = "n" if skip_last_base

    single_read_string = compress_use_bases_string(s)
    if sample_mixture.sample_prep_kit.paired_end
      return "#{single_read_string},#{single_read_string}"
    else
      return single_read_string
    end
  end
  
private
  
  def sequence_sample_mixture
    sample_mixture.sequence!
  end
  
  def unsequence_sample_mixture
    sample_mixture.unsequence!
  end

  def complete_sample_mixture_and_flow_cell
    sample_mixture.complete!
    flow_cell.complete!
  end

  def compress_use_bases_string(original)
    compressed = ""

    repeats = original.scan(/(Y+|n+)/)
    repeats.each do |r|
      if(/Y+/.match(r[0]))
        compressed += "Y#{r[0].length}"
      elsif(/n+/.match(r[0]))
        compressed += "n#{r[0].length}"
      end
    end

    return compressed
  end
end
