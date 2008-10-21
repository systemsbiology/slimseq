class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  has_and_belongs_to_many :samples
  
  validates_numericality_of :starting_concentration, :loaded_concentration

  after_create :mark_samples_as_clustered
  before_destroy :mark_samples_as_submitted

  acts_as_state_machine :initial => :clustered, :column => 'status'
  
  state :clustered, :after => [:unsequence_samples, :clear_path]
  state :sequenced, :after => [:sequence_samples, :generate_path]
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced    
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered
  end
  
  def sequence_samples
    samples.each do |s|
      s = Sample.find(s.id)
      s.sequence!
    end
  end
  
  def unsequence_samples
    samples.each do |s|
      s = Sample.find(s.id)
      s.unsequence!
    end
  end
  
  def mark_samples_as_clustered
    samples.each do |sample|
      sample = Sample.find(sample.id)
      sample.cluster!
    end
  end
  
  def mark_samples_as_submitted
    samples.each do |sample|
      sample = Sample.find(sample.id)
      sample.unsequence!
      sample.uncluster!
    end
  end
  
  def generate_path
    path = "#{SiteConfig.raw_data_root_path}/#{samples[0].project.lab_group.file_folder}/" +
           "#{samples[0].project.file_folder}/#{flow_cell.sequencing_run.date_yymmdd}_" +
           "#{flow_cell.sequencing_run.instrument.serial_number}_#{flow_cell.name}"
    update_attribute("raw_data_path", path)
  end

  def clear_path
    update_attribute("raw_data_path", "")
  end
  
end
