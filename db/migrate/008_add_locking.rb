class AddLocking < ActiveRecord::Migration
  def self.using_Mysql?
    if(ActiveRecord::Base.connection.adapter_name == "MySQL")
      return true;
    else
      return false;
    end
  end

  def self.up
    if(using_Mysql?)
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
    # hack to get new column on existing records set to 0 with sqlite
    else
      ChargePeriod.dump_to_file
      ChargeSet.dump_to_file
      Charge.dump_to_file
      ChargeTemplate.dump_to_file      
      ChipTransaction.dump_to_file
      ChipType.dump_to_file
      Hybridization.dump_to_file
      InventoryCheck.dump_to_file
      LabGroup.dump_to_file
      Organism.dump_to_file
      SiteConfig.dump_to_file

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

      ChargePeriod.load_from_file
      ChargeSet.load_from_file
      Charge.load_from_file
      ChargeTemplate.load_from_file
      ChipTransaction.load_from_file
      ChipType.load_from_file
      Hybridization.load_from_file
      InventoryCheck.load_from_file
      LabGroup.load_from_file
      Organism.load_from_file
      SiteConfig.load_from_file
    end
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
