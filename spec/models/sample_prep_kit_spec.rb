require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SamplePrepKit do

  it "should provide eland_extended for non-paired end sample prep kits" do
    kit = SamplePrepKit.create(:name => "Regular", :paired_end => false)
    kit.eland_analysis.should == "eland_extended"
  end

  it "should provide eland_pair for paired end sample prep kits" do
    kit = SamplePrepKit.create(:name => "Paired End", :paired_end => true)
    kit.eland_analysis.should == "eland_pair"
  end
end
