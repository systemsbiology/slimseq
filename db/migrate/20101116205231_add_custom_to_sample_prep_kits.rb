class AddCustomToSamplePrepKits < ActiveRecord::Migration
  def self.up
    add_column :sample_prep_kits, :custom, :boolean, :default => false
  end

  def self.down
    remove_column :sample_prep_kits, :custom
  end
end
