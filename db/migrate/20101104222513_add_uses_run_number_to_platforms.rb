class AddUsesRunNumberToPlatforms < ActiveRecord::Migration
  def self.up
    add_column :platforms, :uses_run_number, :boolean, :default => true
  end

  def self.down
    remove_column :platforms, :uses_run_number
  end
end
