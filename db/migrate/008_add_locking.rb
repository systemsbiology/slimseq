class AddLocking < ActiveRecord::Migration
  def self.up
    add_column :charge_periods, :lock_version, :integer, :default => 0
    add_column :charge_sets, :lock_version, :integer, :default => 0
    add_column :charges, :lock_version, :integer, :default => 0
    add_column :charge_templates, :lock_version, :integer, :default => 0
    add_column :chip_transactions, :lock_version, :integer, :default => 0
    add_column :chip_types, :lock_version, :integer, :default => 0
    add_column :hybridizations, :lock_version, :integer, :default => 0
    add_column :inventory_checks, :lock_version, :integer, :default => 0
    add_column :lab_groups, :lock_version, :integer, :default => 0
    add_column :organisms, :lock_version, :integer, :default => 0
    add_column :site_config, :lock_version, :integer, :default => 0
  end

  def self.down
    remove_column :charge_periods, :lock_version
    remove_column :charge_sets, :lock_version
    remove_column :charges, :lock_version
    remove_column :charge_templates, :lock_version
    remove_column :chip_transactions, :lock_version
    remove_column :chip_types, :lock_version
    remove_column :hybridizations, :lock_version
    remove_column :inventory_checks, :lock_version
    remove_column :lab_groups, :lock_version
    remove_column :organisms, :lock_version
    remove_column :site_config, :lock_version
  end
end
