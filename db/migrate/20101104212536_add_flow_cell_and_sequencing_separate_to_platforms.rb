class AddFlowCellAndSequencingSeparateToPlatforms < ActiveRecord::Migration
  def self.up
    add_column :platforms, :flow_cell_and_sequencing_separate, :boolean, :default => true
  end

  def self.down
    remove_column :platforms, :flow_cell_and_sequencing_separate
  end
end
