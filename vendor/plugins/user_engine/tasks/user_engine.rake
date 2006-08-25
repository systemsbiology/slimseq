desc 'Import the User Engine schema.'
task :import_user_engine_schema => [:import_login_engine_schema, :environment] do
  load "#{Engines.get(:user).root}/db/schema.rb"
end

desc 'Create the default roles/permissions/users'
task :bootstrap => [:sync_permissions, :create_roles, :create_admin_user]

desc 'Add any new controller/action permissions to the authorization database'
task :sync_permissions => :environment do
  Permission.synchronize_with_controllers
end

desc 'Create the administrator super-user'
task :create_admin_user => :environment do
  # Create the administrator user, if needed
  if User.find_by_login(UserEngine.config(:admin_login)) == nil
    puts "Creating admin user '#{UserEngine.config(:admin_login)}'"
    u = User.new
    u.login = UserEngine.config(:admin_login)
    u.firstname = "System"
    u.lastname = "Administrator"
    u.email = UserEngine.config(:admin_email)
    u.change_password UserEngine.config(:admin_password)
    u.verified = 1
    raise "Couldn't save administrator!" if !u.save
  end

  u = User.find_by_login(UserEngine.config(:admin_login))
  if !u.roles.include?(Role.find_by_name(UserEngine.config(:admin_role_name)))
    u.roles << Role.find_by_name(UserEngine.config(:admin_role_name))
  end

  raise "Couldn't save administrator after assigning roles!" if !u.save
end

desc 'Create the default roles'
task :create_roles => :environment do

  # Create the Guest Role
  if Role.find_by_name(UserEngine.config(:guest_role_name)) == nil
    puts "Creating guest role '#{UserEngine.config(:guest_role_name)}'"
    guest = Role.new
    guest.name = UserEngine.config(:guest_role_name)
    guest.description = "Implicit role for all accessors of the site"
    guest.system_role = true
    guest.omnipotent = false
    raise "Couldn't save guest role!" if !guest.save

    guest.permissions << Permission.find_by_controller_and_action('user', 'login')
    guest.permissions << Permission.find_by_controller_and_action('user', 'forgot_password')

    raise "Couldn't save guest role after setting permissions!" if !guest.save
  end

  @all_action_permissions = Permission.find_all

  # Create the Admin role
  if Role.find_by_name(UserEngine.config(:admin_role_name)) == nil
    puts "Creating admin role '#{UserEngine.config(:admin_role_name)}'"
    admin = Role.new
    admin.name = UserEngine.config(:admin_role_name)
    admin.description = "The system administrator, with REAL ULTIMATE POWER."
    admin.omnipotent = true
    admin.system_role = true
    raise "Couldn't save admin role!" if !admin.save

    @all_action_permissions.each { |permission|
      if !admin.permissions.include?(permission)
        admin.permissions << permission
      end
    }

    raise "Couldn't save admin role after assigning permissions!" if !admin.save
  end

  # Create the User role, if needed
  if Role.find_by_name(UserEngine.config(:user_role_name)) == nil
    puts "Creating user role '#{UserEngine.config(:user_role_name)}'"
    user = Role.new
    user.name = UserEngine.config(:user_role_name)
    user.description = "Customers, who can submit and check on samples, " + 
                       "as well as look at their array inventories. "
    user.system_role = true
    user.omnipotent = false
    raise "Couldn't save default user role!" if !user.save

    # all users automatically get the Guest permissions implicitly
    user.permissions << Permission.find_by_controller_and_action('user', 'logout')
    user.permissions << Permission.find_by_controller_and_action('user', 'home')
    user.permissions << Permission.find_by_controller_and_action('user', 'change_password')
    user.permissions << Permission.find_by_controller_and_action('user', 'edit')

    # SLIMarray-specific permissions
    user.permissions << Permission.find_by_controller_and_action('chip_transactions', 'list_subset')
    user.permissions << Permission.find_by_controller_and_action('inventory', 'index')
    user.permissions << Permission.find_by_controller_and_action('samples', 'new')
    user.permissions << Permission.find_by_controller_and_action('samples', 'list')
    user.permissions << Permission.find_by_controller_and_action('samples', 'add')
    user.permissions << Permission.find_by_controller_and_action('samples', 'clear')
    user.permissions << Permission.find_by_controller_and_action('samples', 'edit')
    user.permissions << Permission.find_by_controller_and_action('samples', 'destroy')
    user.permissions << Permission.find_by_controller_and_action('samples', 'create')
    user.permissions << Permission.find_by_controller_and_action('samples', 'show')
    user.permissions << Permission.find_by_controller_and_action('samples', 'index')
    user.permissions << Permission.find_by_controller_and_action('samples', 'update')
        
    raise "Couldn't save default user role after assigning permissions!" if !user.save
  end

  # Create the Staff role, if needed
  if Role.find_by_name("Staff") == nil
    puts "Creating user role 'Staff'"
    staff = Role.new
    staff.name = "Staff"
    staff.description = "Members of the facility staff, who can do just about " + 
                        "anything except manage users and site configuration. "
    staff.system_role = true
    staff.omnipotent = false
    raise "Couldn't save default user role!" if !staff.save

    # all users automatically get the Guest permissions implicitly
    staff.permissions << Permission.find_by_controller_and_action('user', 'logout')
    staff.permissions << Permission.find_by_controller_and_action('user', 'home')
    staff.permissions << Permission.find_by_controller_and_action('user', 'staff')
    staff.permissions << Permission.find_by_controller_and_action('user', 'change_password')
    staff.permissions << Permission.find_by_controller_and_action('user', 'edit')

    # SLIMarray-specific permissions
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'new')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'list')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'create')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'show')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'index')
    staff.permissions << Permission.find_by_controller_and_action('organisms', 'update')
    
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'new')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'list_subset')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'create')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'index')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'totals')
    staff.permissions << Permission.find_by_controller_and_action('chip_transactions', 'update')
    
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'new')
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'list')
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'create')
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'index')
    staff.permissions << Permission.find_by_controller_and_action('charge_templates', 'update')
     
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'new')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'list')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'add')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'clear')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'create')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'show')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'index')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'update')
    staff.permissions << Permission.find_by_controller_and_action('hybridizations', 'order_hybridizations')
    
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'new')
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'list')
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'create')
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'index')
    staff.permissions << Permission.find_by_controller_and_action('chip_types', 'update')
    
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'new')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'list')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'create')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'show')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'index')
    staff.permissions << Permission.find_by_controller_and_action('lab_groups', 'update')
    
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'new')
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'excel')
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'create')
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'pdf')
    staff.permissions << Permission.find_by_controller_and_action('charge_periods', 'update')
    
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'new')
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'list')
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'create')
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'index')
    staff.permissions << Permission.find_by_controller_and_action('inventory_checks', 'update')   
     
    staff.permissions << Permission.find_by_controller_and_action('charges', 'new')
    staff.permissions << Permission.find_by_controller_and_action('charges', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('charges', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('charges', 'create')
    staff.permissions << Permission.find_by_controller_and_action('charges', 'update')
    staff.permissions << Permission.find_by_controller_and_action('charges', 'list_within_charge_set')
    
    staff.permissions << Permission.find_by_controller_and_action('samples', 'new')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'list')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'add')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'clear')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'create')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'show')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'index')
    staff.permissions << Permission.find_by_controller_and_action('samples', 'update')

    staff.permissions << Permission.find_by_controller_and_action('inventory', 'index')
    
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'new')
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'list')
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'edit')
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'destroy')
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'create')
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'index')
    staff.permissions << Permission.find_by_controller_and_action('charge_sets', 'update')
        
    raise "Couldn't save Staff role after assigning permissions!" if !staff.save
  end
end