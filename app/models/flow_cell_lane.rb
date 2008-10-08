class FlowCellLane < ActiveRecord::Base
  belongs_to :flow_cell
  
  has_and_belongs_to_many :samples
  
  validates_numericality_of :starting_concentration, :loaded_concentration
end
