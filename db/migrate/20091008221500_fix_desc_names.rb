class FixDescNames < ActiveRecord::Migration
  def self.up
    rename_column :experiments, "desc", "description"
  end

  def self.down
    rename_column :experiments, "description", "desc"
  end
end
