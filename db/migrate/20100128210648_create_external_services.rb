class CreateExternalServices < ActiveRecord::Migration
  def self.up
    create_table :external_services do |t|
      t.string :uri, :null => false
      t.boolean :authentication, :null => false
      t.string :username
      t.string :password
      t.boolean :sample_status_notification, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :external_services
  end
end
