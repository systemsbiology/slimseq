class PipelineRun < ActiveRecord::BaseWithoutTable
  column :base_directory, :string
  column :summary_files, :string
  column :eland_output_files, :string
  column :sequencing_run_id, :integer
  column :full_validation, :boolean, :default => false
  
  has_many :pipeline_results
  belongs_to :sequencing_run

  validates_presence_of :base_directory
  validates_format_of :base_directory, :with => /^\/.*\/.*\/(.*?)_(.*?)_(.*?)$/
  validates_presence_of :summary_files
  validates_presence_of :eland_output_files

  validates_presence_of :sequencing_run_id, :if => :full_validation,
    :message => "couldn't be found based on the provided run folder"
  validates_associated :sequencing_run, :if => :full_validation

  def validate
    if(:full_validation == true)
      errors.add("No new results to record (may be redundant with existing results)", "")
    end
  end
  
  def self.new(attributes=nil)
    pipeline_run = super(attributes)

    if(pipeline_run.valid?)
      match = /^\/.*\/.*\/(.*?)_(.*?)_((\d+)_)*(FC)*(.*)\/*$/.match(attributes[:base_directory])
      original_date = match[1]
      date = Date.strptime(original_date,"%y%m%d")
      sequencer = match[2]
      flow_cell = match[6]

      pipeline_run.sequencing_run = SequencingRun.find(:first, 
        :include => [:instrument, :flow_cell],
        :conditions => ["date = ? AND instruments.serial_number = ? AND flow_cells.name = ?",
          date, sequencer, flow_cell])

      unless(pipeline_run.sequencing_run.nil?)
        summaries = pipeline_run.summary_files.split(/,/)
        eland_by_gerald_and_lane = eland_outputs_by_gerald_and_lane(pipeline_run.eland_output_files)
        eland_by_gerald_and_lane.sort.each do |gerald, eland_by_lane|
          eland_by_lane.sort.each do |lane_number, eland_output_paths|
            lane = pipeline_run.sequencing_run.flow_cell.flow_cell_lanes.find(:first,
              :conditions => {:lane_number => lane_number})

            original_gerald_date = 
              /GERALD_(\d+-\d+-\d+)/.match(gerald)[1]
            gerald_date = Date.strptime(original_gerald_date,"%d-%m-%Y")

            summary_file = summaries.grep(/#{gerald}/).first
            
            existing_result = PipelineResult.find(:first, :conditions => {
                :base_directory => pipeline_run.base_directory,
                :summary_file => summary_file,
                :gerald_date => gerald_date,
                :sequencing_run_id => pipeline_run.sequencing_run_id,
                :flow_cell_lane_id => lane.id
              }
            )
            
            # only add a result if one doesn't already exist
            if(existing_result == nil)
              pipeline_run.pipeline_results << PipelineResult.new(
                :base_directory => pipeline_run.base_directory,
                :summary_file => summary_file,
                :output_files => eland_output_paths,
                :gerald_date => gerald_date,
                :sequencing_run => pipeline_run.sequencing_run,
                :flow_cell_lane => lane
              )
            end
          end
        end
      end
      
      # now allow full validation
      pipeline_run.full_validation = true

    end
        
    return pipeline_run
  end
  
  def self.eland_outputs_by_gerald_and_lane(file_string)
    files = file_string.split(/,/)

    result = Hash.new

    files.each do |file|
      match = /(GERALD_\d+-\d+-\d+)_.*s_(\d)_(\d_)*(export|eland_result).txt/.match(file)
      gerald = match[1]
      lane_number = match[2]

      if match
        result[gerald] ||= Hash.new
        result[gerald][lane_number] ||= Array.new
        result[gerald][lane_number] << file
      end
    end

    return result
  end

end
