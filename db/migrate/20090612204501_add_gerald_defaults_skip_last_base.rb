class AddGeraldDefaultsSkipLastBase < ActiveRecord::Migration
  def self.up
    add_column :gerald_defaults, :skip_last_base, :boolean, :default => false
  end

  def self.down
    remove_column :gerald_defaults, :skip_last_base
  end
end
