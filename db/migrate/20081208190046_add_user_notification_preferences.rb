class AddUserNotificationPreferences < ActiveRecord::Migration
  def self.up
    add_column :users, :new_sample_notification, :boolean, :default => false
    add_column :users, :new_sequencing_run_notification, :boolean, :default => false
  end

  def self.down
    remove_column :users, :new_sample_notification
    remove_column :users, :new_sequencing_run_notification
  end
end
