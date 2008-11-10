require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChargeTemplate do
  it "should provide the default charge template" do
    # create a default template
    default_template = create_charge_template(:default => true)
    
    # create another template that won't be set as the default
    create_charge_template
    
    ChargeTemplate.default.should == default_template
  end
  
  it "should turn off default status on all other templates when a new template is created " +
     "with default set to true" do
    old_default_id = create_charge_template(:default => true).id
    create_charge_template(:default => true)

    old_default = ChargeTemplate.find(old_default_id)
    old_default.default.should == false
  end
end
