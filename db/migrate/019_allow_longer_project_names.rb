class AllowLongerProjectNames < ActiveRecord::Migration
  def self.up
    change_column :projects, :name, :string, :limit => 250
  end

  def self.down
    change_column :projects, :name, :string, :limit => 50
  end
end
