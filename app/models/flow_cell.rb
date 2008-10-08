class FlowCell < ActiveRecord::Base
  has_many :flow_cell_lanes, :dependent => :destroy
  
  belongs_to :sequencing_run
  
  validates_presence_of :name, :date_generated
  validates_uniqueness_of :name
  
  def lane_attributes=(lane_attributes)
    lane_attributes.each do |attributes|
      flow_cell_lanes.build(attributes)
    end
  end
end
