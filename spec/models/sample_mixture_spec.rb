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

end
