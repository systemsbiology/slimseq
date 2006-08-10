class AddAdministratorEmail < ActiveRecord::Migration
  def self.up
    add_column :site_config, :administrator_email, :string, :limit => 100
    
    SiteConfig.reset_column_information
    SiteConfig.update 1, :administrator_email => "webmaster@your.site.com"
  end

  def self.down
    remove_column :site_config, :administrator_email
  end
end
