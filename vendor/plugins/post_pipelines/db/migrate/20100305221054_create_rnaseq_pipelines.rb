class CreateRnaseqPipelines < ActiveRecord::Migration
  def self.up
    create_table :rnaseq_pipelines do |t|
      t.string :label, :null=>false
      t.string :status, :null=>false, default=>'Not started'
      t.integer :sample_id, :null=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :rnaseq_pipelines
  end
end
