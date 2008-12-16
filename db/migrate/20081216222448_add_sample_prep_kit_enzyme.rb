class AddSamplePrepKitEnzyme < ActiveRecord::Migration
  def self.up
    add_column :sample_prep_kits, :restriction_enzyme, :string
  end

  def self.down
    remove_column :sample_prep_kits, :restriction_enzyme
  end
end
