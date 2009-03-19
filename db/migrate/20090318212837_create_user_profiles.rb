class CreateUserProfiles < ActiveRecord::Migration
  def self.up
    create_table :user_profiles do |t|
      t.integer :user_id
      t.string :role, :default => "customer"
      t.boolean :new_sample_notification, :default => false
      t.boolean :new_sequencing_run_notification, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :user_profiles
  end
end
