class FlowCellLaneNumberOfCycles < ActiveRecord::Migration
  def self.up
    add_column :flow_cell_lanes, :number_of_cycles, :integer

    FlowCellLane.reset_column_information

    FlowCellLane.all.each do |l|
      l.update_attribute('number_of_cycles', l.samples.first.desired_read_length)
    end
  end

  def self.down
    remove_column :flow_cell_lanes, :number_of_cycles
  end
end
