module FixtureReplacement

  attributes_for :charge_period do |cp|
    cp.name = String.random
  end

  attributes_for :charge_set do |cs|
    cs.lab_group_id = 1
    cs.charge_period = default_charge_period
    cs.name = String.random
    cs.budget_manager = String.random
    cs.budget = String.random
  end

  attributes_for :charge_template do |ct|
    ct.name = String.random
    ct.description = String.random(20)
    ct.cost = 100
    ct.default = false
  end

#  attributes_for :charge do |a|
#    
#  end

  attributes_for :flow_cell_lane do |l|
    l.flow_cell = default_flow_cell
    l.lane_number = 1
    l.starting_concentration = 2345
    l.loaded_concentration = 2
    l.status = "submitted"
    l.comment = ""
    l.samples = [default_sample]
  end

  attributes_for :flow_cell do |f|
    f.name = String.random
    f.date_generated = Date.today
    f.status = "clustered"    
    f.comment = ""
  end

  attributes_for :instrument do |i|
    i.name = String.random
    i.serial_number = String.random    
  end

  attributes_for :naming_element do |ne|
    ne.naming_scheme = default_naming_scheme
    ne.name = String.random
    ne.group_element = true
    ne.optional = true
    ne.free_text = false
    ne.dependent_element_id = nil
  end

  attributes_for :naming_scheme do |ns|
    ns.name = String.random
  end

  attributes_for :naming_term do |nt|
    nt.naming_element = default_naming_element
    nt.term = String.random
    nt.abbreviated_term = String.random(3)
  end

  attributes_for :organism do |o|
    o.name = String.random
  end

  attributes_for :project do |p|
    p.name = String.random
    p.file_folder = String.random
  end

  attributes_for :reference_genome do |r|
    r.name = String.random
    r.description = String.random
    r.organism = default_organism
    r.fasta_path = "/path/to/fasta"
  end

  attributes_for :sample_prep_kit do |spk|
    spk.name = String.random
  end

  attributes_for :sample_term do |st|
    st.sample = default_sample
    st.naming_term = default_naming_term
  end

  attributes_for :sample_text do |st|
    st.sample = default_sample
    st.naming_element = default_naming_element
  end

  attributes_for :sample do |s|
    s.project = default_project
    s.submission_date = Date.today
    s.name_on_tube = String.random(5)
    s.sample_description = String.random(30)
    s.sample_prep_kit = default_sample_prep_kit
    s.insert_size = 200
    s.desired_read_length = 36
    s.alignment_start_position = 1
    s.alignment_end_position = 36
    s.reference_genome = default_reference_genome
    s.status = "submitted"
    s.budget_number = 1234
    s.control = false
    s.comment = ""
  end

  attributes_for :sequencing_run do |sr|
    sr.flow_cell = default_flow_cell
    sr.instrument = default_instrument
    sr.date = Date.today
    sr.comment = ""
  end

#  attributes_for :site_config do |a|
#    
#  end

  attributes_for :pipeline_result do |pr|
    run_name = String.random
    
    pr.flow_cell_lane = default_flow_cell_lane
    pr.sequencing_run = default_sequencing_run
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
    gd.header = "ANALYSIS eland_extended\nSEQUENCE_FORMAT --fasta\nELAND_MULTIPLE_INSTANCES 8"
    gd.skip_last_base = false
  end
end
