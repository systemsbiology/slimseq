class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  has_many :samples
end
