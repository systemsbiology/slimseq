class AddReferenceGenomeFastaPath < ActiveRecord::Migration
  def self.up
    add_column :reference_genomes, :fasta_path, :string
  end

  def self.down
    remove_column :reference_genomes, :fasta_path
  end
end
