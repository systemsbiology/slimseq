class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  has_and_belongs_to_many :samples
  
  validates_numericality_of :starting_concentration, :loaded_concentration

  after_create :mark_samples_as_clustered
  before_destroy :mark_samples_as_submitted

  acts_as_state_machine :initial => :clustered, :column => 'status'
  
  state :clustered, :after => :unsequence_samples
  state :sequenced, :after => :sequence_samples
  
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
      sample.uncluster!
    end
  end

end
