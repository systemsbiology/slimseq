require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sample_prep_kits/edit.html.erb" do
  include SamplePrepKitsHelper
  
  before(:each) do
    assigns[:sample_prep_kit] = @sample_prep_kit = stub_model(SamplePrepKit,
      :new_record? => false,
      :name => "value for name"
    )
  end

  it "should render edit form" do
    render "/sample_prep_kits/edit.html.erb"
    
    response.should have_tag("form[action=#{sample_prep_kit_path(@sample_prep_kit)}][method=post]") do
      with_tag('input#sample_prep_kit_name[name=?]', "sample_prep_kit[name]")
    end
  end
end


