require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/flow_cells/edit.html.erb" do
  include FlowCellsHelper
  
  before(:each) do
    assigns[:flow_cell] = @flow_cell = stub_model(FlowCell,
      :new_record? => false
    )
  end

  it "should render edit form" do
    render "/flow_cells/edit.html.erb"
    
    response.should have_tag("form[action=#{flow_cell_path(@flow_cell)}][method=post]") do
    end
  end
end


