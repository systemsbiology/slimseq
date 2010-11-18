class CreatePrimers < ActiveRecord::Migration
  def self.up
    create_table :primers do |t|
      t.string :name
      t.boolean :custom, :default => false
      t.integer :platform_id

      t.timestamps
    end
  end

  def self.down
    drop_table :primers
  end
end
