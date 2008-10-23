require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChargeSet" do
  fixtures :charge_sets, :charges

  it "get totals" do
    expected_totals = Hash.new(0)
    expected_totals = { "cost" => 150, "total_cost" => 150}

    set = charge_sets(:mouse_jan)
    set.get_totals.should == expected_totals
  end

  it "destroy warning" do
    expected_warning = "Destroying this charge set will also destroy:\n" + 
                       "2 charge(s)\n" +
                       "Are you sure you want to destroy it?"
  
    set = charge_sets(:mouse_jan)
    set.destroy_warning.should == expected_warning
  end
end
