require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/flow_cells/show.html.erb" do
  include FlowCellsHelper
  
  before(:each) do
    assigns[:flow_cell] = @flow_cell = stub_model(FlowCell)
  end

  it "should render attributes in <p>" do
    render "/flow_cells/show.html.erb"
  end
end

