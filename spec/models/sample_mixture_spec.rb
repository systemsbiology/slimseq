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
  
end
