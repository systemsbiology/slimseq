class AddInstrumentVersion < ActiveRecord::Migration
  def self.up
    add_column :instruments, :instrument_version, :string
    add_column :instruments, :active, :boolean, :default => true
  end

  def self.down
    remove_column :instruments, :instrument_version
    remove_column :instruments, :active
  end
end
