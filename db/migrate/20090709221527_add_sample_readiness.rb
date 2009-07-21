class AddSampleReadiness < ActiveRecord::Migration
  def self.up
    add_column :samples, :ready_for_sequencing, :boolean, :null => false, :default => true
    add_column :lab_group_profiles, :samples_need_approval, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :samples, :ready_for_sequencing
    remove_column :lab_group_profiles, :samples_need_approval
  end
end
