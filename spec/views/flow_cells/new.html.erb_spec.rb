require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/flow_cells/new.html.erb" do
  include FlowCellsHelper
  
  before(:each) do
    assigns[:flow_cell] = stub_model(FlowCell,
      :new_record? => true
    )
  end

  it "should render new form" do
    render "/flow_cells/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", flow_cells_path) do
    end
  end
end


