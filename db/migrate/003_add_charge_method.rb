class AddChargeMethod < ActiveRecord::Migration
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
        # add the new column
        add_column :charge_sets, :charge_method, :string, :limit => 20
    
        # populate existing charge sets as being 'internal' charges
        ChargeSet.reset_column_information
        ChargeSet.find(:all).each do |cs|
          cs.charge_method = "internal"
          cs.save
        end
      end
    else
      # add the new column
      add_column :charge_sets, :charge_method, :string, :limit => 20
  
      # populate existing charge sets as being 'internal' charges
      ChargeSet.reset_column_information
      ChargeSet.find(:all).each do |cs|
        cs.charge_method = "internal"
        cs.save
      end    
    end
  end

  def self.down
    remove_column :charge_sets, :charge_method
  end
end
