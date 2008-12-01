class AddPipelineResults < ActiveRecord::Migration
  def self.up
    create_table "pipeline_results", :force => true do |t|
      t.column "flow_cell_lane_id", :integer
      t.column "sequencing_run_id", :integer
      t.column "base_directory", :string
      t.column "summary_file", :string
      t.column "eland_output_file", :string
      t.column "gerald_date", :date
      t.column "lock_version", :integer, :default => 0
      
      t.timestamps
    end
    
    # move existing raw data paths over to this new model
    FlowCellLane.find(:all).each do |l|
      if(l.sequenced? && l.raw_data_path != nil && l.raw_data_path != "")
        PipelineResult.create(
          :flow_cell_lane => l,
          :sequencing_run => l.flow_cell.sequencing_run,
          :base_directory => l.raw_data_path
        )
      end
    end
    
    remove_column :flow_cell_lanes, :raw_data_path
  end

  def self.down
    add_column :flow_cell_lanes, :raw_data_path, :string
    
    PipelineResult.find(:all).each do |p|
      lane = p.flow_cell_lane
      lane.update_attribute('raw_data_path', p.base_directory)
    end
    
    drop_table :pipeline_results
  end
end
