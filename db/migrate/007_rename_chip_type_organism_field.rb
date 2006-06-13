class RenameChipTypeOrganismField < ActiveRecord::Migration
  def self.up
    rename_column :chip_types, :default_organism_id, :organism_id
  end

  def self.down
  end
end
