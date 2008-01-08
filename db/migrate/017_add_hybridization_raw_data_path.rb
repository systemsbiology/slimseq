class AddHybridizationRawDataPath < ActiveRecord::Migration
  def self.up
    add_column :hybridizations, :raw_data_path, :string, :limit => 400
    add_column :site_config, :raw_data_root_path, :string, :limit => 200
  end

  def self.down
    remove_column :hybridizations, :raw_data_path
    remove_column :site_config, :raw_data_root_path
  end
end
