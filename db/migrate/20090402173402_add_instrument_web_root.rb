class AddInstrumentWebRoot < ActiveRecord::Migration
  def self.up
    add_column :instruments, :web_root, :string
  end

  def self.down
    remove_column :instruments, :web_root
  end
end
