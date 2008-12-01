class FlowCell < ActiveRecord::Base
  has_many :flow_cell_lanes, :dependent => :destroy
  
  has_many :sequencing_runs, :dependent => :destroy
  
  validates_presence_of :name, :date_generated
  validates_uniqueness_of :name

  acts_as_state_machine :initial => :clustered, :column => 'status'
  
  state :clustered, :after => :unsequence_lanes
  state :sequenced, :after => :sequence_lanes
  state :completed, :after => :complete_lanes
  
  event :sequence do
    transitions :from => :clustered, :to => :sequenced    
  end

  event :unsequence do
    transitions :from => :sequenced, :to => :clustered    
  end
  
  event :complete do
    transitions :from => :sequenced, :to => :completed    
  end

  def new_lane_attributes=(lane_attributes)
    lane_attributes.each do |attributes|
      flow_cell_lanes.build(attributes)
    end
  end
  
  def existing_lane_attributes=(lane_attributes)
    flow_cell_lanes.reject(&:new_record?).each do |lane|
      attributes = lane_attributes[lane.id.to_s]
      if attributes
        lane.attributes = attributes
        lane.save
      end
    end
  end
  
  def summary_hash
    return {
      :id => id,
      :name => name,
      :date_generated => date_generated,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/flow_cells/#{id}"
    }
  end
  
  def detail_hash
    if(sequencing_runs.size == 0)
      sequencer_hash = {}
    else
      sequencing_run = sequencing_runs[0]
      sequencer_hash = {
        :name => sequencing_run.instrument.name,
        :serial_number => sequencing_run.instrument.serial_number,
        :instrument_version => sequencing_run.instrument.instrument_version
      }
    end
    
    return {
      :id => id,
      :name => name,
      :date_generated => date_generated,
      :updated_at => updated_at,
      :comment => comment,
      :status => status,
      :sequencer => sequencer_hash,
      :flow_cell_lane_uris => flow_cell_lane_ids.collect {
        |x| "#{SiteConfig.site_url}/flow_cell_lanes/#{x}"
      }
    }
  end
  
private
  
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
  
  def complete_lanes
    flow_cell_lanes.each do |l|
      l.complete!
    end
  end
end
