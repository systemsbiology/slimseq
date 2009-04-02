class AddFlowCellLaneQualityMetrics < ActiveRecord::Migration
  def self.up
    add_column :flow_cell_lanes, :lane_yield_kb, :integer
    add_column :flow_cell_lanes, :average_clusters, :integer
    add_column :flow_cell_lanes, :percent_pass_filter_clusters, :float
    add_column :flow_cell_lanes, :percent_align, :float
    add_column :flow_cell_lanes, :percent_error, :float
  end

  def self.down
    remove_column :flow_cell_lanes, :lane_yield_kb
    remove_column :flow_cell_lanes, :average_clusters
    remove_column :flow_cell_lanes, :percent_pass_filter_clusters
    remove_column :flow_cell_lanes, :percent_align
    remove_column :flow_cell_lanes, :percent_error
  end
end
