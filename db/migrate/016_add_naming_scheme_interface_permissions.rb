class AddNamingSchemeInterfacePermissions < ActiveRecord::Migration
  def self.up
    # create new permissions
    Rake::Task[:sync_permissions].invoke
    
    # If staff role exists, give access to new naming scheme management interfaces
    staff_role = Role.find(:first, :conditions => "name = 'Staff'")
    if(staff_role != nil)
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'index')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'list')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'new')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'create')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'rename')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'update')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_schemes', 'destroy')

      staff_role.permissions << Permission.find_by_controller_and_action('naming_elements', 'list_for_naming_scheme')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_elements', 'new')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_elements', 'create')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_elements', 'edit')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_elements', 'update')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_elements', 'destroy')
      
      staff_role.permissions << Permission.find_by_controller_and_action('naming_terms', 'list_for_naming_element')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_terms', 'create')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_terms', 'edit')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_terms', 'update')
      staff_role.permissions << Permission.find_by_controller_and_action('naming_terms', 'destroy')
    end
  end

  def self.down
  end
end
