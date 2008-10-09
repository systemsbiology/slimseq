class SequencingRun < ActiveRecord::Base
  belongs_to :flow_cell
  belongs_to :instrument
  
  after_create :mark_flow_cell_and_samples_as_sequenced
  before_destroy :mark_flow_cell_and_samples_as_clustered
  
  def mark_flow_cell_and_samples_as_sequenced
    mark_flow_cell_and_samples_as('sequenced')
  end
  
  def mark_flow_cell_and_samples_as_clustered
    mark_flow_cell_and_samples_as('clustered')
  end
  
  def mark_flow_cell_and_samples_as(status)
    flow_cell.update_attribute('status', status)
    flow_cell.flow_cell_lanes.each do |l|
      l.samples.each do |sample|
        sample.update_attribute('status', status)
      end
    end
  end
end
