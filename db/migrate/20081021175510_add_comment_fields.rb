class AddCommentFields < ActiveRecord::Migration
  def self.up
    add_column :samples, :comment, :string
    add_column :flow_cells, :comment, :string
    add_column :flow_cell_lanes, :comment, :string
    add_column :sequencing_runs, :comment, :string
  end

  def self.down
    remove_column :samples, :comment
    remove_column :flow_cells, :comment
    remove_column :flow_cell_lanes, :comment
    remove_column :sequencing_runs, :comment
  end
end
