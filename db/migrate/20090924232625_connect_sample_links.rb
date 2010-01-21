class ConnectSampleLinks < ActiveRecord::Migration
  def self.up
    add_column :samples, :experiment_id, :integer
    add_column :experiments, :study_id, :integer
    add_column :studies, :project_id, :integer
  end

  def self.down
    remove_column :samples, :experiment_id
    remove_column :experiments, :study_id
    remove_column :studies, :project_id
  end
end
