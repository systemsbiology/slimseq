class CreatePostPipelines < ActiveRecord::Migration
  def self.up
    create_table :post_pipelines do |t|
      t.integer :runtype, :default=>0, :null=>false
      t.integer :max_mismatches, :default=>1
      t.string :name, :null=>false
      t.string :status, :default=>'Not started', :null=>false

      # going to copy some info from pipeline_result objects for ease of use later:
      t.integer :pipeline_result_id, :null=>false
      t.integer :sample_id, :null=>false
      t.integer :flow_cell_lane_id, :null=>false
      t.integer :reference_genome_id, :null=>false
      t.string :working_dir, :null=>false
      t.string :export_file, :null=>false
      t.string :ref_genome_path, :null=>false
      t.string :org_name, :null=>false

      t.timestamps
    end

  end

  def self.down
    drop_table :post_pipelines
  end
end
