require 'spec_helper'

describe SampleMixture do
  describe "providing eland seed length" do
    
    before(:each) do
      GeraldDefaults.destroy_all
      create_gerald_defaults(:eland_seed_length => 25, :eland_max_matches => 5)
      @eland_parameter_set = create_eland_parameter_set(:name => "mouse", :eland_seed_length => 20, :eland_max_matches => 10)
    end
    
    it "should provide the seed length from the sample_mixture's eland parameter set if one is specified" do
      sample_mixture = create_sample_mixture(:eland_parameter_set_id => @eland_parameter_set.id)
      sample_mixture.eland_seed_length.should == 20
    end

    it "should provide the application-wide gerald default seed length if no sample_mixture eland parameter set exists" do
      sample_mixture = create_sample_mixture
      sample_mixture.eland_seed_length.should == 25
    end

    it "should provide a seed length of 17 if the eland seed length is 25 but the desired read length is 18" do
      sample_mixture = create_sample_mixture(:desired_read_length => 18)
      sample_mixture.eland_seed_length.should == 17
    end
  end

  describe "providing eland max matches" do
    
    before(:each) do
      GeraldDefaults.destroy_all
      create_gerald_defaults(:eland_seed_length => 25, :eland_max_matches => 5)
      @eland_parameter_set = create_eland_parameter_set(:name => "mouse", :eland_seed_length => 20, :eland_max_matches => 10)
    end
    
    it "should provide the max matches from the sample_mixture's eland parameter set if one is specified" do
      sample_mixture = create_sample_mixture(:eland_parameter_set_id => @eland_parameter_set.id)
      sample_mixture.eland_max_matches.should == 10
    end

    it "should provide the application-wide gerald default max matches if no sample_mixture eland parameter set exists" do
      sample_mixture = create_sample_mixture
      sample_mixture.eland_max_matches.should == 5
    end

  end

  it "should provide the sample mixtures accessible to a user" do
    lab_group_1 = mock_model(LabGroup, :destroyed? => false)
    lab_group_2 = mock_model(LabGroup, :destroyed? => false)
    user = mock_model(User, :get_lab_group_ids => [lab_group_1.id])
    sample_mixture_1 = create_sample_mixture( :project => create_project(:lab_group => lab_group_1) )
    sample_mixture_2 = create_sample_mixture( :project => create_project(:lab_group => lab_group_2) )
    
    SampleMixture.accessible_to_user(user).should == [sample_mixture_1]
  end

  describe "providing comments from associated flow cell lanes, flow cells and sequencing runs" do

    it "should provide a concatenated string when there are some comments" do
      sample_mixture = create_sample_mixture(:comment => "weird IP")
      flow_cell = create_flow_cell(:comment => "Flow was all wrong")
      lane_1 = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell,
                                     :comment => "Concentration unsually high")
      lane_2 = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell)
      sequencing_run = create_sequencing_run(:flow_cell => flow_cell, :comment => "Prism messed up")
      
      sample_mixture.associated_comments.should == "sample_mixture: weird IP, lane: Concentration unsually high, " +
        "flow cell: Flow was all wrong, sequencing: Prism messed up"
    end

    it "should provide 'No comments' when there aren't any" do
      sample_mixture = create_sample_mixture
      flow_cell = create_flow_cell
      lane_1 = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell)
      lane_2 = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell)
      sequencing_run = create_sequencing_run(:flow_cell => flow_cell)
      
      sample_mixture.associated_comments.should == "No comments"
    end

  end

  describe "notifying external services of status changes" do

    it "should notify external services when a sample_mixture is clustered" do
      sample_mixture = create_sample_mixture
      sample = create_sample(:sample_mixture => sample_mixture)
      ExternalService.should_receive(:sample_status_change).with(sample).once
      sample_mixture.reload.cluster!
    end

    it "should notify external services when a sample_mixture is sequenced" do
      sample_mixture = create_sample_mixture
      sample = create_sample(:sample_mixture => sample_mixture)
      ExternalService.should_receive(:sample_status_change).with(sample).twice
      sample_mixture.reload.cluster!
      sample_mixture.sequence!
    end

    it "should notify external services when a sample_mixture is completed" do
      sample_mixture = create_sample_mixture
      sample = create_sample(:sample_mixture => sample_mixture)
      ExternalService.should_receive(:sample_status_change).with(sample).exactly(3).times
      sample_mixture.reload.cluster!
      sample_mixture.sequence!
      sample_mixture.complete!
    end

    it "should notify external services when a sample_mixture goes back to the submitted state" do
      sample_mixture = create_sample_mixture
      sample = create_sample(:sample_mixture => sample_mixture)
      ExternalService.should_receive(:sample_status_change).with(sample).twice
      sample_mixture.reload.cluster!
      sample_mixture.uncluster!
    end
  end
  
  it "should provide browsing categories" do
    # make sure there are no other schemes to get in the way
    NamingScheme.destroy_all

    scheme = create_naming_scheme(:name => "Mouse")
    strain = create_naming_element(:naming_scheme => scheme, :name => "Strain")

    SampleMixture.browsing_categories.should == [
      ['Flow Cell', 'flow_cell'],
      ['Insert Size', 'insert_size'],
      ['Lab Group', 'lab_group'],
      ['Naming Scheme', 'naming_scheme'],
      ['Organism', 'organism'],
      ['Project', 'project'],
      ['Reference Genome', 'reference_genome'],
      ['Sample Prep Kit', 'sample_prep_kit'],
      ['Status', 'status'],
      ['Submission Date', 'submission_date'],
      ['Submitter', 'submitter'],
      ['Mouse: Strain', "naming_element-#{strain.id}"]
    ]
  end

  it "should find by a set of conditions after sanitizing them" do
    scheme = create_naming_scheme(:name => "Mouse")
    strain = create_naming_element(:naming_scheme => scheme, :name => "Strain")
    bl6 = create_naming_term(:naming_element => strain, :term => "Bl6")
    mutant = create_naming_term(:naming_element => strain, :term => "Mutant")
    age = create_naming_element(:naming_scheme => scheme, :name => "Age")
    one_week = create_naming_term(:naming_element => age, :term => "One Week")
    two_weeks = create_naming_term(:naming_element => age, :term => "Two Weeks")
    lab_group_1 = mock_model(LabGroup, :name => "Smith Lab", :destroyed? => false)
    project_1 = create_project(:name => "ChIP-Seq", :lab_group => lab_group_1)
    project_2 = create_project(:name => "RNA-Seq")
    flow_cell = create_flow_cell
    genome = create_reference_genome
    prep_kit = create_sample_prep_kit
    sample_mixture_1 = create_sample_mixture(:project => project_1, :submission_date => '2009-05-01',
      :sample_prep_kit => prep_kit)
    sample_mixture_2 = create_sample_mixture(:project => project_1, :submission_date => '2009-05-02')
    sample_mixture_3 = create_sample_mixture(:project => project_1, :submission_date => '2009-05-01')
    sample_1 = create_sample(:insert_size => 100, :naming_scheme_id => scheme.id,
                             :reference_genome => genome, :sample_mixture => sample_mixture_1)
    sample_2 = create_sample(:insert_size => 150, :sample_mixture => sample_mixture_2)
    sample_3 = create_sample(:insert_size => 100, :naming_scheme_id => scheme.id,
                             :reference_genome => genome, :sample_mixture => sample_mixture_1)
    sample_4 = create_sample(:sample_mixture => sample_mixture_3)
    flow_cell_lane = create_flow_cell_lane(:sample_mixture => sample_mixture_1, :flow_cell => flow_cell)
    create_sample_term(:sample => sample_1, :naming_term => bl6)
    create_sample_term(:sample => sample_2, :naming_term => mutant)
    create_sample_term(:sample => sample_3, :naming_term => bl6)
    create_sample_term(:sample => sample_4, :naming_term => bl6)
    create_sample_term(:sample => sample_1, :naming_term => one_week)
    create_sample_term(:sample => sample_2, :naming_term => one_week)
    create_sample_term(:sample => sample_3, :naming_term => two_weeks)
    create_sample_term(:sample => sample_4, :naming_term => two_weeks)

    SampleMixture.find_by_sanitized_conditions(
      "controller" => "this",
      "action" => "that",
      "project_id" => project_1.id,
      "submission_date" => '2009-05-01',
      "insert_size" => 100,
      "reference_genome_id" => genome.id,
      "organism_id" => genome.organism_id,
      "status" => "clustered",
      "naming_scheme_id" => scheme.id,
      "naming_term_id" => "#{one_week.id},#{bl6.id}",
      "flow_cell_id" => flow_cell.id,
      "lab_group_id" => lab_group_1.id,
      "bob_id" => 123
    ).should == [sample_mixture_1]
  end
end
