class CreateSampleSets < ActiveRecord::Migration
  def self.up
    create_table :sample_sets do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :sample_sets
  end
end
