class AddFlowCellLaneStatus < ActiveRecord::Migration
  def self.up
    add_column :flow_cell_lanes, :status, :string, :default => 'clustered'
  end

  def self.down
    remove_column :flow_cell_lanes, :status
  end
end
