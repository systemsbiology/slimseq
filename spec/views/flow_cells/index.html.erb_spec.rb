require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/flow_cells/index.html.erb" do
  include FlowCellsHelper
  
  before(:each) do
    assigns[:flow_cells] = [
      stub_model(FlowCell),
      stub_model(FlowCell)
    ]
  end

  it "should render list of flow_cells" do
    render "/flow_cells/index.html.erb"
  end
end

