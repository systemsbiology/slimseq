class CreateRnaseqStats < ActiveRecord::Migration
  def self.up
    create_table :rnaseq_stats do |t|
      t.integer :total_reads, :null=>false
      t.integer :total_aligned, :null=>false
      t.integer :unique_aligned, :null=>false
      t.integer :spliced_aligned, :null=>false
      t.integer :multi_aligned, :null=>false
      t.integer :n_genes, :null=>false

      t.integer :post_pipeline_id, :null=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :rnaseq_stats
  end
end
