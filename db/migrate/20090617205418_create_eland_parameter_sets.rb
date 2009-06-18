class CreateElandParameterSets < ActiveRecord::Migration
  def self.up
    create_table :eland_parameter_sets do |t|
      t.string :name
      t.integer :eland_seed_length
      t.integer :eland_max_matches
    end

    add_column :samples, :eland_parameter_set_id, :integer
  end

  def self.down
    drop_table :eland_parameter_sets

    remove_column :samples, :eland_parameter_set_id
  end
end
