class CreateTagCountPipelineTable < ActiveRecord::Migration
  def self.up
    create_table "tag_count_pipelines" do |t|
      t.string :label, :null=>false
      t.string :status, :null=>false
      t.integer :sample_id, :null=>false
      t.integer :n_mismatches, :null=>false, :default=>1
      t.integer :reference_genome_id, :null=>false
      t.integer :flow_cell_lane_id, :null=>false
      t.integer :pipeline_results_id, :null=>false

    end
  end

  def self.down
    drop_table "tag_count_pipelines"
  end
end
