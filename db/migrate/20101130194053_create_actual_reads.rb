class CreateActualReads < ActiveRecord::Migration
  def self.up
    create_table :actual_reads do |t|
      t.integer :read_order
      t.integer :number_of_cycles
      t.integer :flow_cell_lane_id

      t.timestamps
    end

    FlowCellLane.all.each do |lane|
      lane.actual_reads.create(:read_order => 1, :number_of_cycles => lane.number_of_cycles)
      lane.save
    end

    remove_column :flow_cell_lanes, :number_of_cycles
  end

  def self.down
    raise "This migration is not reversible"
  end
end
