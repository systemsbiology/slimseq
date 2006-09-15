class AddStaffCustomerRoles < ActiveRecord::Migration
  def self.up
    # The easiest way to create the new Customer and Staff roles is by using
    # the rake boostrap task
    Rake::Task[:bootstrap].invoke
    
    # Change existing Users to Customers
    user_role = Role.find(:first, :conditions => "name = 'User'")
    customer_role = Role.find(:first, :conditions => "name = 'Customer'")
    User.find(:all).each do |u|
      if( u.roles.include?(user_role) )
        u.roles.delete(user_role)
        u.roles << customer_role if !u.roles.include?(customer_role)
      end
      u.save
    end
    
    # Then destroy the User role, which requires first making it a
    # non-system role
    user_role.system_role = 0
    user_role.destroy
  end

  def self.down
    # Create the User role
    user_role = Role.new( :name => "User",
                          :description => "The default role for all logged-in users",
                          :omnipotent => 0,
                          :system_role => 1)
                          
    customer_role = Role.find(:first, :conditions => "name = 'Customer'")
    staff_role = Role.find(:first, :conditions => "name = 'Staff'")
    admin_role = Role.find(:first, :conditions => "name = 'Admin'")
    
    User.find(:all).each do |u|
      # Change all Customers back to Users
      if( u.roles.include?(customer_role) )
        u.roles.delete(customer_role)
        u.roles << user_role if !u.roles.include?(user_role)
      end
      # Change all Staff to Admin, since their intermediate access level no
      # longer exists
      if( u.roles.include?(staff_role) )
        u.roles.delete(staff_role)
        u.roles << admin_role if !u.roles.include?(admin_role)
      end
      u.save
    end
    
    # Destroy the Staff and Customer roles, which first requires
    # making Customer a non-system role
    customer_role.system_role = 0
    customer_role.destroy
    staff_role.system_role = 0
    staff_role.destroy
  end
end
