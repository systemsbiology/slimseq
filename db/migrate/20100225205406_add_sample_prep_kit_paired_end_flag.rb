class AddSamplePrepKitPairedEndFlag < ActiveRecord::Migration
  def self.up
    add_column :sample_prep_kits, :paired_end, :boolean, :default => false
  end

  def self.down
    remove_column :sample_prep_kits, :paired_end
  end
end
