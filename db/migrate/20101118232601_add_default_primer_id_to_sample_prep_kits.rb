class AddDefaultPrimerIdToSamplePrepKits < ActiveRecord::Migration
  def self.up
    add_column :sample_prep_kits, :default_primer_id, :integer
  end

  def self.down
    remove_column :sample_prep_kits, :default_primer_id
  end
end
