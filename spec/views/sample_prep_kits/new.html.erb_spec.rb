require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sample_prep_kits/new.html.erb" do
  include SamplePrepKitsHelper
  
  before(:each) do
    assigns[:sample_prep_kit] = stub_model(SamplePrepKit,
      :new_record? => true,
      :name => "value for name"
    )
  end

  it "should render new form" do
    render "/sample_prep_kits/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", sample_prep_kits_path) do
      with_tag("input#sample_prep_kit_name[name=?]", "sample_prep_kit[name]")
    end
  end
end


