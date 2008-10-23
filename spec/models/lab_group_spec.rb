require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "LabGroup" do
  fixtures :lab_groups, :samples, :charge_sets, :projects

  it "should provide an accurate destroy warning" do
    expected_warning = "Destroying this lab group will also destroy:\n" + 
                       "3 charge set(s)\n" +
                       "2 project(s)\n" +
                       "Are you sure you want to destroy it?"

    group = LabGroup.find( lab_groups(:gorilla_group).id )   
    group.destroy_warning.should == expected_warning
  end
end
