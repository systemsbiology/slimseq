require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChargeSet" do
  fixtures :charge_sets, :charges

  it "get totals" do
    set = charge_sets(:mouse_jan)
    set.total_cost.should == 150
  end

  it "destroy warning" do
    expected_warning = "Destroying this charge set will also destroy:\n" + 
                       "2 charge(s)\n" +
                       "Are you sure you want to destroy it?"
  
    set = charge_sets(:mouse_jan)
    set.destroy_warning.should == expected_warning
  end

  it "should find or create a charge set that doesn't exist" do
    charge_period = create_charge_period
    project = create_project
    project.stub!(:lab_group_id).and_return(1)
    set = ChargeSet.find_or_create_for_latest_charge_period(project, "1234")
    set.budget.should == "1234"
    set.charge_period.should == charge_period
    set.name.should == project.name
    set.lab_group_id.should == 1
  end

  it "should find or create a charge set that does exist" do
    charge_period = create_charge_period
    project = create_project
    project.stub!(:lab_group_id).and_return(1)
    charge_set = create_charge_set(:budget => "1234", :lab_group_id => project.lab_group_id,
                                   :name => project.name, :charge_period => charge_period)
    found_set = ChargeSet.find_or_create_for_latest_charge_period(project, "1234")
    found_set.should == charge_set
  end
end
