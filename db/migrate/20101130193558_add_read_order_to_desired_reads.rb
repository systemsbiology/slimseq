class AddReadOrderToDesiredReads < ActiveRecord::Migration
  def self.up
    add_column :desired_reads, :read_order, :integer, :default => 1
  end

  def self.down
    remove_column :desired_reads, :read_order
  end
end
