class AddSamplePostbackUri < ActiveRecord::Migration
  def self.up
    add_column :samples, :postback_uri, :string
  end

  def self.down
    remove_column :samples, :postback_uri
  end
end
