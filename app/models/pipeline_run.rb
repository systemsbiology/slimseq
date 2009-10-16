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
      original_date = /^\/.*\/.*\/(.*?)_(.*?)_(FC)*(.*?)\/*$/.match(attributes[:base_directory])[1]
      date = Date.strptime(original_date,"%y%m%d")
      sequencer = /^\/.*\/.*\/(.*?)_(.*?)_(FC)*(.*?)\/*$/.match(attributes[:base_directory])[2]
      flow_cell = /^\/.*\/.*\/(.*?)_(.*?)_(FC)*(.*?)\/*$/.match(attributes[:base_directory])[4]

      pipeline_run.sequencing_run = SequencingRun.find(:first, 
        :include => [:instrument, :flow_cell],
        :conditions => ["date = ? AND instruments.serial_number = ? AND flow_cells.name = ?",
          date, sequencer, flow_cell])

      unless(pipeline_run.sequencing_run.nil?)
        summaries = hash_summaries_by_gerald(pipeline_run.summary_files)
        eland_outputs = hash_eland_outputs_by_gerald(pipeline_run.eland_output_files)
        if(summaries.keys == eland_outputs.keys)
          summaries.keys.sort.each do |gerald_folder|
            eland_outputs[gerald_folder].sort.each do |eland_output|
              lane_number = /.*s_(\d)_(export|eland_result).txt/.match(eland_output)[1]

              lane = pipeline_run.sequencing_run.flow_cell.flow_cell_lanes.find(:first,
                :conditions => {:lane_number => lane_number})

              original_gerald_date = 
                /GERALD_(\d+-\d+-\d+)_.*/.match(gerald_folder)[1]
              gerald_date = Date.strptime(original_gerald_date,"%d-%m-%Y")
              
              existing_result = PipelineResult.find(:first, :conditions => {
                  :base_directory => pipeline_run.base_directory,
                  :summary_file => summaries[gerald_folder],
                  :eland_output_file => eland_output,
                  :gerald_date => gerald_date,
                  :sequencing_run_id => pipeline_run.sequencing_run_id,
                  :flow_cell_lane_id => lane.id
                }
              )
              
              # only add a result if one doesn't already exist
              if(existing_result == nil)
                pipeline_run.pipeline_results << PipelineResult.new(
                  :base_directory => pipeline_run.base_directory,
                  :summary_file => summaries[gerald_folder],
                  :eland_output_file => eland_output,
                  :gerald_date => gerald_date,
                  :sequencing_run => pipeline_run.sequencing_run,
                  :flow_cell_lane => lane
                )
              end
            end
          end
        end
      end
      
      # now allow full validation
      pipeline_run.full_validation = true

    end
        
    return pipeline_run
  end
  
  def self.hash_summaries_by_gerald(file_string)
    by_date = Hash.new
    
    files = file_string.split(/\s*,\s*/)
    
    files.each do |file|
      match = /.*(GERALD_\d+-\d+-\d+_.*)\/(\w|\.)+$/.match(file)
      if(match != nil)
        gerald_folder = /.*(GERALD_\d+-\d+-\d+_.*)\/(\w|\.)+$/.match(file)[1]
        
        by_date[gerald_folder] = file
      end
    end
    
    return by_date
  end
  
  def self.hash_eland_outputs_by_gerald(file_string)
    by_date = Hash.new
    
    files = file_string.split(/\s*,\s*/)
    
    files.each do |file|
      match = /.*(GERALD_\d+-\d+-\d+_.*)\/(\w|\.)+$/.match(file)
      if(match != nil)
        gerald_folder = /.*(GERALD_\d+-\d+-\d+_.*)\/(\w|\.)+$/.match(file)[1]
        
        by_date[gerald_folder] ||= Array.new
        by_date[gerald_folder] << file
      end
    end
    
    return by_date
  end
end
