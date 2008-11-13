class AddReferenceGenomeDescription < ActiveRecord::Migration
  def self.up
    add_column :reference_genomes, :description, :string, :default => ""
    
    ReferenceGenome.find(:all).each do |rg|
      rg.update_attribute('description', rg.name)
    end
  end

  def self.down
    remove_column :reference_genomes, :description
  end
end
