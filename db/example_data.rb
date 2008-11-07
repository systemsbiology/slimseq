module FixtureReplacement
#  attributes_for :charge_period do |a|
#    
#  end
#
#  attributes_for :charge_set do |a|
#    
#  end
#
#  attributes_for :charge_template do |a|
#    
#  end
#
#  attributes_for :charge do |a|
#    
#  end

  attributes_for :flow_cell_lane do |l|
    l.flow_cell = default_flow_cell
    l.lane_number = 1
    l.starting_concentration = 2345
    l.loaded_concentration = 2
    l.raw_data_path = "/path/to/data"
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

  attributes_for :lab_group do |lg|
    lg.name = String.random
    lg.file_folder = String.random
  end

#  attributes_for :lab_membership do |a|
#    
#  end
#
#  attributes_for :naming_element do |a|
#    
#  end
#
#  attributes_for :naming_scheme do |a|
#    
#  end
#
#  attributes_for :naming_term do |a|
#    
#  end

  attributes_for :organism do |o|
    o.name = String.random
  end

  attributes_for :project do |p|
    p.name = String.random
    p.lab_group = default_lab_group
    p.file_folder = String.random
  end

  attributes_for :reference_genome do |r|
    r.name = String.random
    r.organism = default_organism
    r.fasta_path = "/path/to/fasta"
  end

  attributes_for :sample_prep_kit do |spk|
    spk.name = String.random
  end

#  attributes_for :sample_term do |a|
#    
#  end
#
#  attributes_for :sample_text do |a|
#    
#  end

  attributes_for :sample do |s|
    s.user = default_user
    s.project = default_project
    s.submission_date = Date.today
    s.short_sample_name = String.random(5)
    s.sample_name = String.random(30)
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

  attributes_for :user do |u|
    password = String.random
    
    u.login = String.random
    u.email = String.random + "@example.com"
    u.firstname = String.random
    u.lastname = String.random
    u.role = "customer"
    u.password = password
    u.password_confirmation = password
  end

end