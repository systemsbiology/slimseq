require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sample_prep_kits/show.html.erb" do
  include SamplePrepKitsHelper
  
  before(:each) do
    assigns[:sample_prep_kit] = @sample_prep_kit = stub_model(SamplePrepKit,
      :name => "value for name"
    )
  end

  it "should render attributes in <p>" do
    render "/sample_prep_kits/show.html.erb"
    response.should have_text(/value\ for\ name/)
  end
end

