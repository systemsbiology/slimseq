class CreateMultiplexCodes < ActiveRecord::Migration
  def self.up
    create_table :multiplex_codes do |t|
      t.string :sequence
      t.integer :multiplexing_scheme_id
      t.string :name

      t.timestamps
    end

    add_column :samples, :multiplex_code_id, :integer
  end

  def self.down
    drop_table :multiplex_codes

    remove_column :samples, :multiplex_code_id
  end
end
