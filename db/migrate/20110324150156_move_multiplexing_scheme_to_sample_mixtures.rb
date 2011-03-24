class MoveMultiplexingSchemeToSampleMixtures < ActiveRecord::Migration
  def self.up
    add_column :sample_mixtures, :multiplexing_scheme_id, :integer
    remove_column :sample_prep_kits, :multiplexing_scheme_id
  end

  def self.down
    remove_column :sample_mixtures, :multiplexing_scheme_id
    add_column :sample_prep_kits, :multiplexing_scheme_id, :integer
  end
end
