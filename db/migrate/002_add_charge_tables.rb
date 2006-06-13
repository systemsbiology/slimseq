class AddChargeTables < ActiveRecord::Migration
  def self.using_Mysql?
    if(ActiveRecord::Base.connection.adapter_name == "MySQL")
      return true;
    else
      return false;
    end
  end

  def self.up
    if(using_Mysql?)
      transaction do
        add_column :hybridizations, :charge_template_id, :integer
    
        add_column :add_hybs, :charge_template_id, :integer
        
        create_table "charges", :force => true do |t|
          t.column "charge_set_id", :integer
          t.column "date", :date
          t.column "description", :string, :limit => 100
          t.column "chips_used", :integer
          t.column "chip_cost", :float
          t.column "labeling_cost", :float      
          t.column "hybridization_cost", :float
          t.column "qc_cost", :float
          t.column "other_cost", :float
        end

        add_index "charges", ["charge_set_id"], :name => "charge_set_id"
        
        create_table "charge_sets", :force => true do |t|
          t.column "lab_group_id", :integer
          t.column "charge_period_id", :integer
          t.column "name", :string, :limit => 50
          t.column "budget_manager", :string, :limit => 50
          t.column "budget", :string, :limit => 8
        end

        add_index "charge_sets", ["lab_group_id"], :name => "lab_group_id"
        add_index "charge_sets", ["charge_period_id"], :name => "charge_period_id"
        
        create_table "charge_periods", :force => true do |t|
          t.column "name", :string, :limit => 50
        end
        
        create_table "charge_templates", :force => true do |t|
          t.column "name", :string, :limit => 40
          t.column "description", :string, :limit => 100
          t.column "chips_used", :integer
          t.column "chip_cost", :float
          t.column "labeling_cost", :float      
          t.column "hybridization_cost", :float
          t.column "qc_cost", :float
          t.column "other_cost", :float
        end
      end
    else
      add_column :hybridizations, :charge_template_id, :integer
  
      add_column :add_hybs, :charge_template_id, :integer
      
      create_table "charges", :force => true do |t|
        t.column "charge_set_id", :integer
        t.column "date", :date
        t.column "description", :string, :limit => 100
        t.column "chips_used", :integer
        t.column "chip_cost", :float
        t.column "labeling_cost", :float      
        t.column "hybridization_cost", :float
        t.column "qc_cost", :float
        t.column "other_cost", :float
      end
           
      create_table "charge_sets", :force => true do |t|
        t.column "lab_group_id", :integer
        t.column "charge_period_id", :integer
        t.column "name", :string, :limit => 50
        t.column "budget_manager", :string, :limit => 50
        t.column "budget", :string, :limit => 8
      end
  
      create_table "charge_periods", :force => true do |t|
        t.column "name", :string, :limit => 50
      end
      
      create_table "charge_templates", :force => true do |t|
        t.column "name", :string, :limit => 40
        t.column "description", :string, :limit => 100
        t.column "chips_used", :integer
        t.column "chip_cost", :float
        t.column "labeling_cost", :float      
        t.column "hybridization_cost", :float
        t.column "qc_cost", :float
        t.column "other_cost", :float
      end
    end
  end

  def self.down
    if(using_Mysql?)
      transaction do
        remove_column :hybridizations, :charge_template_id
        remove_column :add_hybs, :charge_template_id
        drop_table :charges
        drop_table :charge_sets
        drop_table :charge_periods
        drop_table :charge_templates    
      end
    else
      remove_column :hybridizations, :charge_template_id
      remove_column :add_hybs, :charge_template_id
      drop_table :charges
      drop_table :charge_sets
      drop_table :charge_periods
      drop_table :charge_templates 
    end
  end
end
