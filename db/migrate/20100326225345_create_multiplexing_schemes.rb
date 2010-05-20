class CreateMultiplexingSchemes < ActiveRecord::Migration
  def self.up
    create_table :multiplexing_schemes do |t|
      t.string :name

      t.timestamps
    end

    add_column :sample_prep_kits, :multiplexing_scheme_id, :integer
  end

  def self.down
    drop_table :multiplexing_schemes

    remove_column :sample_prep_kits, :multiplexing_scheme_id
  end
end
