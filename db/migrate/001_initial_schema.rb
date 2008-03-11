class InitialSchema < ActiveRecord::Migration
  def self.up
    transaction do
      create_table "add_hybs", :force => true do |t|
        t.column "number", :integer
        t.column "lab_group_id", :integer
        t.column "chip_type_id", :integer
        t.column "date", :date
        t.column "sbeams_user", :string, :limit => 20
        t.column "sbeams_project", :string, :limit => 50
      end
    
      create_table "chip_transactions", :force => true do |t|
        t.column "lab_group_id", :integer, :default => 0, :null => false
        t.column "chip_type_id", :integer, :default => 0, :null => false
        t.column "date", :date, :null => false
        t.column "description", :string
        t.column "acquired", :integer, :limit => 5
        t.column "used", :integer, :limit => 5
        t.column "traded_sold", :integer, :limit => 5
        t.column "borrowed_in", :integer, :limit => 5
        t.column "returned_out", :integer, :limit => 5
        t.column "borrowed_out", :integer, :limit => 5
        t.column "returned_in", :integer, :limit => 5
      end
    
      create_table "chip_types", :force => true do |t|
        t.column "name", :string, :limit => 20, :default => "", :null => false
        t.column "short_name", :string, :limit => 20, :default => "", :null => false
        t.column "default_organism_id", :integer, :default => 0, :null => false
      end
    
      create_table "hybridizations", :force => true do |t|
        t.column "date", :date
        t.column "chip_number", :integer, :limit => 4
        t.column "short_sample_name", :string, :limit => 8
        t.column "sample_name", :string, :limit => 48
        t.column "sample_group_name", :string, :limit => 50
        t.column "lab_group_id", :integer
        t.column "chip_type_id", :integer
        t.column "organism_id", :integer, :default => 0, :null => false
        t.column "sbeams_user", :string, :limit => 20
        t.column "sbeams_project", :string, :limit => 50
      end
    
      create_table "inventory_checks", :force => true do |t|
        t.column "date", :date, :null => false
        t.column "lab_group_id", :integer
        t.column "chip_type_id", :integer
        t.column "number_expected", :integer
        t.column "number_counted", :integer
      end
    
      create_table "lab_groups", :force => true do |t|
        t.column "name", :string, :limit => 20, :default => "", :null => false
      end
    
      create_table "organisms", :force => true do |t|
        t.column "name", :string, :limit => 50
      end
      
      create_table "users", :force => true do |t|
        t.column "login", :string, :limit => 80, :default => "", :null => false
        t.column "salted_password", :string, :limit => 40, :default => "", :null => false
        t.column "email", :string, :limit => 60, :default => "", :null => false
        t.column "firstname", :string, :limit => 40
        t.column "lastname", :string, :limit => 40
        t.column "salt", :string, :limit => 40, :default => "", :null => false
        t.column "verified", :integer, :default => 0
        t.column "role", :string, :limit => 40
        t.column "security_token", :string, :limit => 40
        t.column "token_expiry", :datetime
        t.column "created_at", :datetime
        t.column "updated_at", :datetime
        t.column "logged_in_at", :datetime
        t.column "deleted", :integer, :default => 0
        t.column "delete_after", :datetime
      end
    end
  end

  def self.down
    transaction do
      drop_table :add_hybs
      drop_table :chip_transactions
      drop_table :chip_types
      drop_table :engine_schema_info
      drop_table :hybridizations
      drop_table :inventory_checks
      drop_table :lab_groups
      drop_table :organisms
      drop_table :permissions
      drop_table :permissions_roles
      drop_table :roles
      drop_table :users
      drop_table :users_roles
    end
  end
end
