class CreateStudies < ActiveRecord::Migration
  def self.up
    create_table :studies do |t|
      t.string :name
      t.string :description
#      t.experiments :has_many
#      t.project :belongs_to

      t.timestamps
    end
  end

  def self.down
    drop_table :studies
  end
end
