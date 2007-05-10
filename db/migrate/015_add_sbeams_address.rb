class AddSbeamsAddress < ActiveRecord::Migration
  def self.up
    add_column :site_config, :sbeams_address, :string, :limit => 200
    
    SiteConfig.reset_column_information
    SiteConfig.update 1, :sbeams_address => "http://myserver/sbeams"
  end

  def self.down
    remove_column :site_config, :sbeams_address
  end
end
