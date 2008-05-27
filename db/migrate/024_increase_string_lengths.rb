class IncreaseStringLengths < ActiveRecord::Migration
  def self.up
    transaction do
      change_column :projects, :name, :string, :limit => 250
      change_column :projects, :budget, :string, :limit => 100
      change_column :chip_types, :name, :string, :limit => 250
      change_column :chip_types, :short_name, :string, :limit => 100
      change_column :lab_groups, :name, :string, :limit => 250
      change_column :charge_sets, :budget, :string, :limit => 100
    end
  end

  def self.down
    transaction do
      change_column :projects, :name, :string, :limit => 50
      change_column :chip_types, :name, :string, :limit => 20
      change_column :chip_types, :short_name, :string, :limit => 20
      change_column :lab_groups, :name, :string, :limit => 20
      change_column :charge_sets, :budget, :string, :limit => 8
    end
  end
end
