class InitialSchema < ActiveRecord::Migration
  def self.up
    transaction do
      create_table "samples", :force => true do |t|
        t.column "sample_set_id", :integer
        t.column "submitted_by_id", :integer
        t.column "project_id", :integer
        t.column "submission_date", :date
        t.column "short_sample_name", :string
        t.column "sample_name", :string
        t.column "sample_prep_kit_id", :integer
        t.column "insert_size", :integer
        t.column "desired_read_length", :integer
        t.column "alignment_start_position", :integer, :default => 1
        t.column "alignment_end_position", :integer
        t.column "reference_genome_id", :integer
        t.column "status", :string, :default => 'submitted'
        t.column "naming_scheme_id", :integer
        t.column "budget_number", :string
        t.column "control", :boolean, :default => false
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "sample_prep_kits", :force => true do |t|
        t.column "name", :string
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "flow_cells", :force => true do |t|
        t.column "name", :string
        t.column "date_generated", :date
        t.column "status", :string, :default => 'clustered'
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "flow_cell_lanes", :force => true do |t|
        t.column "flow_cell_id", :integer
        t.column "lane_number", :integer
        t.column "starting_concentration", :string
        t.column "loaded_concentration", :string
        t.column "raw_data_path", :string
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "flow_cell_lanes_samples", :id => false, :force => true do |t|
        t.column "sample_id", :integer
        t.column "flow_cell_lane_id", :integer
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "sequencing_runs", :force => true do |t|
        t.column "flow_cell_id", :integer
        t.column "instrument_id", :integer
        t.column "date", :date
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "instruments", :force => true do |t|
        t.column "name", :string
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "lab_groups", :force => true do |t|
        t.column "name", :string
        t.column "file_folder", :string
        t.column "lock_version", :integer, :default => 0
      end

      create_table "projects", :force => true do |t|
        t.column "name", :string
        t.column "file_folder", :string
        t.column "lab_group_id", :integer
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "reference_genomes", :force => true do |t|
        t.column "name", :string
        t.column "organism_id", :integer
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "organisms", :force => true do |t|
        t.column "name", :string
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "users", :force => true do |t|
        t.column "login", :string
        t.column "crypted_password", :string
        t.column "email", :string
        t.column "firstname", :string
        t.column "lastname", :string
        t.column "salt", :string
        t.column "role", :string, :default => "customer"
        t.column "remember_token", :string
        t.column "remember_token_expires_at", :datetime
        t.column "created_at", :datetime
        t.column "updated_at", :datetime
        t.column "lock_version", :integer, :default => 0
      end

      create_table "site_config", :force => true do |t|
        t.column "site_name", :string
        t.column "organization_name", :string
        t.column "facility_name", :string
        t.column "track_charges", :boolean
        t.column "use_LDAP", :boolean
        t.column "LDAP_server", :string
        t.column "LDAP_DN", :string
        t.column "administrator_email", :string
        t.column "raw_data_root_path", :string
        t.column "site_url", :string
        t.column "lock_version", :integer, :default => 0
      end

      create_table "lab_memberships", :force => true do |t|
        t.column "lab_group_id", :integer
        t.column "user_id", :integer
        t.column "lock_version", :integer, :default => 0
      end

      # the naming schemes
      create_table "naming_schemes", :force => true do |t|
        t.column "name", :string
        t.column "lock_version", :integer, :default => 0
      end

      # individual elements of a naming scheme
      create_table "naming_elements", :force => true do |t|
        t.column "name", :string
        t.column "element_order", :integer
        t.column "group_element", :boolean
        t.column "optional", :boolean
        t.column "dependent_element_id", :integer
        t.column "naming_scheme_id", :integer
        t.column "free_text", :boolean
        t.column "include_in_sample_name", :boolean, :default => true
        t.column "lock_version", :integer, :default => 0
      end

      # vocabulary for the naming scheme elements
      create_table "naming_terms", :force => true do |t|
        t.column "term", :string
        t.column "abbreviated_term", :string
        t.column "naming_element_id", :integer
        t.column "term_order", :integer
        t.column "lock_version", :integer, :default => 0
      end

      # terms associated with actual samples
      create_table "sample_terms", :force => true do |t|
        t.column "term_order", :integer
        t.column "sample_id", :integer
        t.column "naming_term_id", :integer
        t.column "lock_version", :integer, :default => 0
      end
      
      # sample-specific free text
      create_table "sample_texts", :force => true do |t|
        t.column "text", :string
        t.column "lock_version", :integer, :default => 0
        t.column "sample_id", :integer
        t.column "naming_element_id", :integer
        t.column "lock_version", :integer, :default => 0
      end
      
      create_table "charges", :force => true do |t|
        t.column "charge_set_id", :integer
        t.column "date", :date
        t.column "description", :string
        t.column "cost", :float
        t.column "lock_version", :integer, :default => 0
      end

      add_index "charges", ["charge_set_id"], :name => "charge_set_id"

      create_table "charge_sets", :force => true do |t|
        t.column "lab_group_id", :integer
        t.column "charge_period_id", :integer
        t.column "name", :string
        t.column "budget_manager", :string
        t.column "budget", :string
        t.column "charge_method", :string
        t.column "lock_version", :integer, :default => 0
      end

      add_index "charge_sets", ["lab_group_id"], :name => "lab_group_id"
      add_index "charge_sets", ["charge_period_id"], :name => "charge_period_id"

      create_table "charge_periods", :force => true do |t|
        t.column "name", :string
        t.column "lock_version", :integer, :default => 0
      end

      create_table "charge_templates", :force => true do |t|
        t.column "name", :string
        t.column "description", :string
        t.column "cost", :float
        t.column "lock_version", :integer, :default => 0
      end
    end
    
  end

  def self.down
    transaction do
      drop_table :lab_memberships
      drop_table :samples
      drop_table :lab_groups
      drop_table :reference_genomes
      drop_table :organisms
      drop_table :flow_cells
      drop_table :flow_cell_lanes
      drop_table :sequencing_runs
      drop_table :instruments
      drop_table :users
      drop_table :charges
      drop_table :charge_sets
      drop_table :charge_periods
      drop_table :charge_templates
      drop_table :site_config
      drop_table :naming_schemes
      drop_table :naming_elements
      drop_table :naming_terms
      drop_table :sample_terms
      drop_table :sample_texts
    end
  end
end
