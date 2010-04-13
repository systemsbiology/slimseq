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

end
