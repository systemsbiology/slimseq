class FixUserSaltColumn < ActiveRecord::Migration
  def self.up
    change_column :users, :salt, :string, :default => "", :null => false
  end

  def self.down
    change_column :users, :salt, :string
  end
end
