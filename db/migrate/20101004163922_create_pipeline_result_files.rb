class CreatePipelineResultFiles < ActiveRecord::Migration
  def self.up
    create_table :pipeline_result_files do |t|
      t.string :file_path
      t.integer :pipeline_result_id

      t.timestamps
    end

    PipelineResult.all.each do |r|
      r.pipeline_result_files.create(:file_path => r.eland_output_file)
    end

    remove_column :pipeline_results, :eland_output_file
  end

  def self.down
    raise "This migration cannot be reversed"
  end
end
