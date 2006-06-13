class AddLabMembership < ActiveRecord::Migration
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
        create_table "lab_memberships", :force => true do |t|
          t.column "lab_group_id", :integer
          t.column "user_id", :integer
        end
      end
    else
      create_table "lab_memberships", :force => true do |t|
        t.column "lab_group_id", :integer
        t.column "user_id", :integer
      end
    end
  end

  def self.down
    drop_table "lab_memberships"
  end
end
