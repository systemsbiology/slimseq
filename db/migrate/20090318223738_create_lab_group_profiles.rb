class CreateLabGroupProfiles < ActiveRecord::Migration
  def self.up
    create_table :lab_group_profiles do |t|
      t.integer :lab_group_id
      t.string :file_folder, :default => ""

      t.timestamps
    end
  end

  def self.down
    drop_table :lab_group_profiles
  end
end
