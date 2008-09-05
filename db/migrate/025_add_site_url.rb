class AddSiteUrl < ActiveRecord::Migration
  def self.up
    add_column :site_config, :site_url, :string
  end

  def self.down
    remove_column :site_config, :site_url
  end
end
