module FixtureReplacement

  attributes_for :flow_cell_lane do |l|
    l.flow_cell = create_flow_cell
    l.lane_number = 1
    l.starting_concentration = 2345
    l.loaded_concentration = 2
    l.status = "submitted"
    l.comment = ""
    l.sample_mixture = create_sample_mixture
  end

  attributes_for :flow_cell do |f|
    f.name = random_string
    f.date_generated = Date.today
    f.status = "clustered"    
    f.comment = ""
  end

  attributes_for :instrument do |i|
    i.name = random_string
    i.serial_number = random_string    
  end

  attributes_for :naming_element do |ne|
    ne.naming_scheme = create_naming_scheme
    ne.name = random_string
    ne.group_element = true
    ne.optional = true
    ne.free_text = false
    ne.dependent_element_id = nil
  end

  attributes_for :naming_scheme do |ns|
    ns.name = random_string
  end

  attributes_for :naming_term do |nt|
    nt.naming_element = create_naming_element
    nt.term = random_string
    nt.abbreviated_term = random_string(3)
  end

  attributes_for :organism do |o|
    o.name = random_string
  end

  attributes_for :project do |p|
    p.name = random_string
    p.file_folder = random_string
  end

  attributes_for :reference_genome do |r|
    r.name = random_string
    r.description = random_string
    r.organism = create_organism
    r.fasta_path = "/path/to/fasta"
  end

  attributes_for :sample_prep_kit do |spk|
    spk.name = random_string
    spk.paired_end = false
  end

  attributes_for :sample_term do |st|
    st.sample = create_sample
    st.naming_term = create_naming_term
  end

  attributes_for :sample_text do |st|
    st.sample = create_sample
    st.naming_element = create_naming_element
  end

  attributes_for :sample do |s|
    s.sample_description = random_string(30)
    s.insert_size = 200
    s.reference_genome = create_reference_genome
    s.sample_mixture = create_sample_mixture
  end

  attributes_for :sample_mixture do |m|
    m.name_on_tube = random_string(5)
    m.sample_description = random_string(30)
    m.project = create_project
    m.submission_date = Date.today
    m.desired_read_length = 36
    m.alignment_start_position = 1
    m.alignment_end_position = 36
    m.control = false
    m.comment = ""
    m.status = "submitted"
    m.budget_number = 1234
    m.sample_prep_kit = create_sample_prep_kit
  end

  attributes_for :sequencing_run do |sr|
    sr.flow_cell = create_flow_cell
    sr.instrument = create_instrument
    sr.date = Date.today
    sr.comment = ""
  end

#  attributes_for :site_config do |a|
#    
#  end

  attributes_for :pipeline_result do |pr|
    run_name = random_string
    
    pr.flow_cell_lane = create_flow_cell_lane
    pr.sequencing_run = create_sequencing_run
    pr.gerald_date = Date.today
    pr.base_directory = "/solexa/lab/project/#{run_name}"
    pr.summary_file = "/solexa/lab/project/#{run_name}/summary.htm"
    pr.eland_output_file = "/solexa/lab/project/#{run_name}/s_1_eland_output.txt"
  end

  attributes_for :user_profile do |up|
    up.role = "customer"
    up.user_id = 1
  end

  attributes_for :gerald_defaults do |gd|
    gd.eland_seed_length = 25
    gd.eland_max_matches = 5
    gd.email_list = "me@localhost"
    gd.email_server = "localhost"
    gd.email_domain = "localhost"
    gd.header = "SEQUENCE_FORMAT --fasta\nELAND_MULTIPLE_INSTANCES 8"
    gd.skip_last_base = false
  end

  attributes_for :eland_parameter_set do |s|
    s.name = random_string
    s.eland_seed_length = 25
    s.eland_max_matches = 5
  end

  attributes_for :lab_group_profile do |p|
    p.file_folder = random_string
    p.lab_group_id = 1
  end

  attributes_for :external_service do |s|
    s.uri = "http://localhost:4567/" + random_string(6)
    s.authentication = false
    s.username = random_string(8)
    s.password = random_string(8)
    s.sample_status_notification = true
    s.json_style = "JSON-wrapped"
    s.authentication_method = "in-JSON"
  end
end
