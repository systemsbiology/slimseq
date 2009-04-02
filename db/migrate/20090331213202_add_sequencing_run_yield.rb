class AddSequencingRunYield < ActiveRecord::Migration
  def self.up
    add_column :sequencing_runs, :yield_kb, :integer
  end

  def self.down
    remove_column :sequencing_runs, :yield_kb
  end
end
