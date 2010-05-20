class AddPipelineResultsArchivedFlag < ActiveRecord::Migration
  def self.up
    add_column :pipeline_results, :archived, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :pipeline_results, :archived
  end
end
