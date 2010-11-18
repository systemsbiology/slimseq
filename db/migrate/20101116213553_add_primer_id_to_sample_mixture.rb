class AddPrimerIdToSampleMixture < ActiveRecord::Migration
  def self.up
    add_column :sample_mixtures, :primer_id, :integer
  end

  def self.down
    remove_column :sample_mixtures, :primer_id
  end
end
