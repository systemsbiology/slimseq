class AddUserParamsPostPipeline < ActiveRecord::Migration
  def self.up
    add_column :post_pipelines, :align_params, :string
    add_column :post_pipelines, :qsub_job_id, :integer
  end
  def self.down
    remove_column :post_pipelines, :align_params
    remove_column :post_pipelines, :qsub_job_id
  end
end
