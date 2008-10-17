class AddInstrumentSerialNumber < ActiveRecord::Migration
  def self.up
    add_column :instruments, :serial_number, :string
  end

  def self.down
    remove_column :instruments, :serial_number
  end
end
