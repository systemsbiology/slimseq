class ActualRead < ActiveRecord::Base
  belongs_to :flow_cell_lane

  def matching_desired_read
    flow_cell_lane.sample_mixture.desired_reads.find_by_read_order(read_order)
  end

end
