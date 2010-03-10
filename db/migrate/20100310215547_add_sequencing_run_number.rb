class AddSequencingRunNumber < ActiveRecord::Migration
  def self.up
    add_column :sequencing_runs, :run_number, :integer
  end

  def self.down
    remove_column :sequencing_runs, :run_number
  end
end
