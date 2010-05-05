class RemovePostPipelineName < ActiveRecord::Migration
  def self.up
    remove_column :post_pipelines, :name
  end

  def self.down
    add_column :post_pipelines, :name, :string
  end
end
