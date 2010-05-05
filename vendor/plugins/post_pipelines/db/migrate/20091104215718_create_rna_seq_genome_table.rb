class CreateRnaSeqGenomeTable < ActiveRecord::Migration
  def self.up
    create_table "rna_seq_ref_genomes" do |t|
      t.string :path, :null=>false
      t.string :name, :null=>false
      t.string :org, :null=>false
      t.string :align :null=>false
      t.int :read_length
      t.string :description
    end
  end

  def self.down
    drop_table "rna_seq_ref_genomes"
  end
end
