class AddReferenceGenomeSolidFields < ActiveRecord::Migration
  def self.up
    add_column :reference_genomes, :filter_reference_path, :string
    add_column :reference_genomes, :gene_gtf_path, :string
  end

  def self.down
    remove_column :reference_genomes, :filter_reference_path
    remove_column :reference_genomes, :gene_gtf_path
  end
end
