class FlowCell < ActiveRecord::Base
  has_many :flow_cell_lanes, :dependent => :destroy
  
  has_one :sequencing_run, :dependent => :destroy
  
  validates_presence_of :name, :date_generated
  validates_uniqueness_of :name

  acts_as_state_machine :initial => :clustered, :column => 'status'
  
  state :clustered, :after => :unsequence_lanes
  state :sequenced, :after => :sequence_lanes
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced    
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered    
  end
  
  def sequence_lanes
    flow_cell_lanes.each do |l|
      l.sequence!
    end
  end

  def unsequence_lanes
    flow_cell_lanes.each do |l|
      l.unsequence!
    end
  end
  
  def lane_attributes=(lane_attributes)
    lane_attributes.each do |attributes|
      flow_cell_lanes.build(attributes)
    end
  end
end
