require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ChargePeriod" do
  fixtures :charge_periods, :charge_sets

  it "should provide a destroy warning" do
    expected_warning = "Destroying this charge period will also destroy:\n" + 
                       "3 charge set(s)\n" +
                       "Are you sure you want to destroy it?"
  
    period = ChargePeriod.find( charge_periods(:january) )   
    period.destroy_warning.should == expected_warning
  end

  it "should provide the latest charge period" do
    first_charge_period = create_charge_period
    second_charge_period = create_charge_period
    
    ChargePeriod.latest.should == second_charge_period
  end
end
