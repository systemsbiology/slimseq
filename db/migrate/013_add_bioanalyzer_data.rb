class AddBioanalyzerData < ActiveRecord::Migration
  def self.up
    # table to hold information about bioanalyzer runs,
    # which are comprised of any number of quality_traces
    create_table "bioanalyzer_runs", :force => true do |t|
      t.column "name", :string, :limit => 100
      t.column "date", :date
      t.column "lock_version", :integer, :default => 0
    end
    
    # an individual quality trace, which has an associated
    # image, name, type, quality rating and is tied
    # to a bioanalyzer_run
    create_table "quality_traces", :force => true do |t|
      t.column "image_path", :string, :limit => 200
      t.column "quality_rating", :string, :limit => 20
      t.column "name", :string, :limit => 100
      t.column "number", :integer
      t.column "sample_type", :string, :limit => 20
      t.column "concentration", :string, :limit => 20
      t.column "ribosomal_ratio", :string, :limit => 20
      t.column "bioanalyzer_run_id", :integer
      t.column "lab_group_id", :integer
      t.column "lock_version", :integer, :default => 0
    end
    
    # samples can now be associated with three types
    # of quality_traces
    add_column :samples, :starting_quality_trace_id, :integer
    add_column :samples, :amplified_quality_trace_id, :integer
    add_column :samples, :fragmented_quality_trace_id, :integer
    
    # add bioanalyzer trace path to site configuration, as
    # well as dropoff location for traces for SBEAMS
    add_column :site_config, :bioanalyzer_pickup, :string, :limit => 250
    add_column :site_config, :quality_trace_dropoff, :string, :limit => 250
    
    # add default paths to site config
    SiteConfig.reset_column_information
    site_config = SiteConfig.find(1)
    site_config.bioanalyzer_pickup = "/tmp/"
    site_config.quality_trace_dropoff = "/tmp/"
    site_config.save
    
    # create new permissions
    Rake::Task[:sync_permissions].invoke
    
    # If customer role exists, give access to new bioanalyzer-related interfaces
    customer_role = Role.find(:first, :conditions => "name = 'Customer'")
    if(customer_role != nil)
      customer_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'list')
      customer_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'show')
      customer_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'index')
      customer_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'pdf')
      
      customer_role.permissions << Permission.find_by_controller_and_action('quality_traces', 'show')

      customer_role.permissions << Permission.find_by_controller_and_action('samples', 'submit_traces')     
      customer_role.permissions << Permission.find_by_controller_and_action('samples', 'new_from_traces')
      customer_role.permissions << Permission.find_by_controller_and_action('samples', 'create_from_traces')
      customer_role.permissions << Permission.find_by_controller_and_action('samples', 'match_traces')
      customer_role.permissions << Permission.find_by_controller_and_action('samples', 'submit_matched_traces')
    end
    
    # If staff role exists, give access to new bioanalyzer-related interfaces
    staff_role = Role.find(:first, :conditions => "name = 'Staff'")
    if(staff_role != nil)
      staff_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'index')
      staff_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'list')
      staff_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'show')
      staff_role.permissions << Permission.find_by_controller_and_action('bioanalyzer_runs', 'destroy')
      
      staff_role.permissions << Permission.find_by_controller_and_action('quality_traces', 'show')

      staff_role.permissions << Permission.find_by_controller_and_action('samples', 'submit_traces')     
      staff_role.permissions << Permission.find_by_controller_and_action('samples', 'new_from_traces')
      staff_role.permissions << Permission.find_by_controller_and_action('samples', 'create_from_traces')
      staff_role.permissions << Permission.find_by_controller_and_action('samples', 'match_traces')
      staff_role.permissions << Permission.find_by_controller_and_action('samples', 'submit_matched_traces')
    end
  end

  def self.down
    remove_column :site_config, :bioanalyzer_pickup
    remove_column :site_config, :quality_trace_dropoff
  
    remove_column :samples, :starting_quality_trace_id
    remove_column :samples, :amplified_quality_trace_id
    remove_column :samples, :fragmented_quality_trace_id

    drop_table :quality_traces
    drop_table :bioanalyzer_runs
  end
end
