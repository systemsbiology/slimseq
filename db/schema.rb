# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100316205813) do

  create_table "charge_periods", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "charge_sets", :force => true do |t|
    t.integer  "lab_group_id"
    t.integer  "charge_period_id"
    t.string   "name"
    t.string   "budget_manager"
    t.string   "budget"
    t.string   "charge_method"
    t.integer  "lock_version",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charge_sets", ["charge_period_id"], :name => "charge_period_id"
  add_index "charge_sets", ["lab_group_id"], :name => "lab_group_id"

  create_table "charge_templates", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.float    "cost"
    t.integer  "lock_version", :default => 0
    t.boolean  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "charges", :force => true do |t|
    t.integer  "charge_set_id"
    t.date     "date"
    t.string   "description"
    t.float    "cost"
    t.integer  "lock_version",  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charges", ["charge_set_id"], :name => "charge_set_id"

  create_table "eland_parameter_sets", :force => true do |t|
    t.string  "name"
    t.integer "eland_seed_length"
    t.integer "eland_max_matches"
  end

  create_table "experiments", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "study_id"
  end

  create_table "external_services", :force => true do |t|
    t.string   "uri",                        :null => false
    t.boolean  "authentication",             :null => false
    t.string   "username"
    t.string   "password"
    t.boolean  "sample_status_notification", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flow_cell_lanes", :force => true do |t|
    t.integer  "flow_cell_id"
    t.integer  "lane_number"
    t.string   "starting_concentration"
    t.string   "loaded_concentration"
    t.integer  "lock_version",                 :default => 0
    t.string   "status",                       :default => "clustered"
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lane_yield_kb"
    t.integer  "average_clusters"
    t.float    "percent_pass_filter_clusters"
    t.float    "percent_align"
    t.float    "percent_error"
    t.integer  "number_of_cycles"
  end

  create_table "flow_cell_lanes_samples", :id => false, :force => true do |t|
    t.integer "sample_id"
    t.integer "flow_cell_lane_id"
    t.integer "lock_version",      :default => 0
  end

  create_table "flow_cells", :force => true do |t|
    t.string   "name"
    t.date     "date_generated"
    t.string   "status",         :default => "clustered"
    t.integer  "lock_version",   :default => 0
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gerald_defaults", :force => true do |t|
    t.string  "email_list",        :default => "admin@example.com"
    t.string  "email_server",      :default => "mail.example.com:25"
    t.string  "email_domain",      :default => "example.com"
    t.integer "eland_seed_length", :default => 25
    t.integer "eland_max_matches", :default => 15
    t.string  "header",            :default => "ANALYSIS eland_extended"
    t.boolean "skip_last_base",    :default => false
  end

  create_table "instruments", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version",       :default => 0
    t.string   "serial_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "instrument_version"
    t.boolean  "active",             :default => true
    t.string   "web_root"
  end

  create_table "lab_group_profiles", :force => true do |t|
    t.integer  "lab_group_id"
    t.string   "file_folder",           :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "samples_need_approval", :default => false, :null => false
  end

  create_table "lab_groups", :force => true do |t|
    t.string   "name"
    t.string   "file_folder"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lab_memberships", :force => true do |t|
    t.integer  "lab_group_id"
    t.integer  "user_id"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "naming_elements", :force => true do |t|
    t.string   "name"
    t.integer  "element_order"
    t.boolean  "group_element"
    t.boolean  "optional"
    t.integer  "dependent_element_id"
    t.integer  "naming_scheme_id"
    t.boolean  "free_text"
    t.boolean  "include_in_sample_description", :default => true
    t.integer  "lock_version",                  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "naming_schemes", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "naming_terms", :force => true do |t|
    t.string   "term"
    t.string   "abbreviated_term"
    t.integer  "naming_element_id"
    t.integer  "term_order"
    t.integer  "lock_version",      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organisms", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pipeline_results", :force => true do |t|
    t.integer  "flow_cell_lane_id"
    t.integer  "sequencing_run_id"
    t.string   "base_directory"
    t.string   "summary_file"
    t.string   "eland_output_file"
    t.date     "gerald_date"
    t.integer  "lock_version",      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",          :default => false, :null => false
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "file_folder"
    t.integer  "lab_group_id"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reference_genomes", :force => true do |t|
    t.string   "name"
    t.integer  "organism_id"
    t.integer  "lock_version",          :default => 0
    t.string   "fasta_path"
    t.string   "description",           :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filter_reference_path"
    t.string   "gene_gtf_path"
  end

  create_table "sample_prep_kits", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version",       :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "restriction_enzyme"
    t.boolean  "paired_end",         :default => false
  end

  create_table "sample_terms", :force => true do |t|
    t.integer  "term_order"
    t.integer  "sample_id"
    t.integer  "naming_term_id"
    t.integer  "lock_version",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sample_texts", :force => true do |t|
    t.string   "text"
    t.integer  "lock_version",      :default => 0
    t.integer  "sample_id"
    t.integer  "naming_element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "samples", :force => true do |t|
    t.integer  "sample_set_id"
    t.integer  "submitted_by_id"
    t.integer  "project_id"
    t.date     "submission_date"
    t.string   "name_on_tube"
    t.string   "sample_description"
    t.integer  "sample_prep_kit_id"
    t.integer  "insert_size"
    t.integer  "desired_read_length"
    t.integer  "alignment_start_position", :default => 1
    t.integer  "alignment_end_position"
    t.integer  "reference_genome_id"
    t.string   "status",                   :default => "submitted"
    t.string   "naming_scheme_id"
    t.string   "budget_number"
    t.boolean  "control",                  :default => false
    t.integer  "lock_version",             :default => 0
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "eland_parameter_set_id"
    t.boolean  "ready_for_sequencing",     :default => true,        :null => false
    t.integer  "experiment_id"
    t.string   "postback_uri"
  end

  create_table "sequencing_runs", :force => true do |t|
    t.integer  "flow_cell_id"
    t.integer  "instrument_id"
    t.date     "date"
    t.integer  "lock_version",  :default => 0
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "best",          :default => true
    t.integer  "yield_kb"
    t.integer  "run_number"
  end

  create_table "site_config", :force => true do |t|
    t.string   "site_name"
    t.string   "organization_name"
    t.string   "facility_name"
    t.boolean  "track_charges"
    t.boolean  "use_LDAP"
    t.string   "LDAP_server"
    t.string   "LDAP_DN"
    t.string   "administrator_email"
    t.string   "raw_data_root_path"
    t.string   "site_url"
    t.integer  "lock_version",        :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "studies", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "role",                            :default => "customer"
    t.boolean  "new_sample_notification",         :default => false
    t.boolean  "new_sequencing_run_notification", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "crypted_password"
    t.string   "email"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "salt",                            :default => "",         :null => false
    t.string   "role",                            :default => "customer"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                    :default => 0
    t.boolean  "new_sample_notification",         :default => false
    t.boolean  "new_sequencing_run_notification", :default => false
  end

end
