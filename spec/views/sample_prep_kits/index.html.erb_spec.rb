require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sample_prep_kits/index.html.erb" do
  include SamplePrepKitsHelper
  
  before(:each) do
    assigns[:sample_prep_kits] = [
      stub_model(SamplePrepKit,
        :name => "value for name"
      ),
      stub_model(SamplePrepKit,
        :name => "value for name"
      )
    ]
  end

  it "should render list of sample_prep_kits" do
    render "/sample_prep_kits/index.html.erb"
    response.should have_tag("tr>td", "value for name", 2)
  end
end

