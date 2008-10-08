require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe FlowCellsController do
  before(:each) do
    login_as_user
    
    Sample.stub!(:find).and_return([mock_model(Sample)])
  end

  def mock_flow_cell(stubs={})
    @mock_flow_cell ||= mock_model(FlowCell, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all flow_cells as @flow_cells" do
      FlowCell.should_receive(:find).with(:all).and_return([mock_flow_cell])
      get :index
      assigns[:flow_cells].should == [mock_flow_cell]
    end

    describe "with mime type of xml" do
  
      it "should render all flow_cells as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        FlowCell.should_receive(:find).with(:all).and_return(flow_cells = mock("Array of FlowCells"))
        flow_cells.should_receive(:to_xml).and_return("generated XML")
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested flow_cell as @flow_cell" do
      FlowCell.should_receive(:find).with("37").and_return(mock_flow_cell)
      get :show, :id => "37"
      assigns[:flow_cell].should equal(mock_flow_cell)
    end
    
    describe "with mime type of xml" do

      it "should render the requested flow_cell as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        FlowCell.should_receive(:find).with("37").and_return(mock_flow_cell)
        mock_flow_cell.should_receive(:to_xml).and_return("generated XML")
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
    before(:each) do
      @flow_cell = mock_flow_cell
      FlowCell.should_receive(:new).and_return(@flow_cell)
      @flow_cell_lanes = [mock_model(FlowCellLane),mock_model(FlowCellLane)]
      @flow_cell.stub!(:flow_cell_lanes).and_return(@flow_cell_lanes)
      @flow_cell_lanes.stub!(:build)
    end
  
    it "should expose a new flow_cell as @flow_cell" do
      get :new
      assigns[:flow_cell].should equal(@flow_cell)
    end
    
    it "should build a set of 8 lanes for the flow cell" do
      @flow_cell_lanes.should_receive(:build).exactly(8).times
      get :new
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested flow_cell as @flow_cell" do
      FlowCell.should_receive(:find).with("37").and_return(mock_flow_cell)
      get :edit, :id => "37"
      assigns[:flow_cell].should equal(mock_flow_cell)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created flow_cell as @flow_cell" do
        FlowCell.should_receive(:new).with({'these' => 'params'}).and_return(mock_flow_cell(:save => true))
        post :create, :flow_cell => {:these => 'params'}
        assigns(:flow_cell).should equal(mock_flow_cell)
      end

      it "should redirect to the created flow_cell" do
        FlowCell.stub!(:new).and_return(mock_flow_cell(:save => true))
        post :create, :flow_cell => {}
        response.should redirect_to(flow_cell_url(mock_flow_cell))
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved flow_cell as @flow_cell" do
        FlowCell.stub!(:new).with({'these' => 'params'}).and_return(mock_flow_cell(:save => false))
        post :create, :flow_cell => {:these => 'params'}
        assigns(:flow_cell).should equal(mock_flow_cell)
      end

      it "should re-render the 'new' template" do
        FlowCell.stub!(:new).and_return(mock_flow_cell(:save => false))
        post :create, :flow_cell => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested flow_cell" do
        FlowCell.should_receive(:find).with("37").and_return(mock_flow_cell)
        mock_flow_cell.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :flow_cell => {:these => 'params'}
      end

      it "should expose the requested flow_cell as @flow_cell" do
        FlowCell.stub!(:find).and_return(mock_flow_cell(:update_attributes => true))
        put :update, :id => "1"
        assigns(:flow_cell).should equal(mock_flow_cell)
      end

      it "should redirect to the flow_cell" do
        FlowCell.stub!(:find).and_return(mock_flow_cell(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(flow_cell_url(mock_flow_cell))
      end

    end
    
    describe "with invalid params" do

      it "should update the requested flow_cell" do
        FlowCell.should_receive(:find).with("37").and_return(mock_flow_cell)
        mock_flow_cell.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :flow_cell => {:these => 'params'}
      end

      it "should expose the flow_cell as @flow_cell" do
        FlowCell.stub!(:find).and_return(mock_flow_cell(:update_attributes => false))
        put :update, :id => "1"
        assigns(:flow_cell).should equal(mock_flow_cell)
      end

      it "should re-render the 'edit' template" do
        FlowCell.stub!(:find).and_return(mock_flow_cell(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested flow_cell" do
      FlowCell.should_receive(:find).with("37").and_return(mock_flow_cell)
      mock_flow_cell.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the flow_cells list" do
      FlowCell.stub!(:find).and_return(mock_flow_cell(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(flow_cells_url)
    end

  end

end
