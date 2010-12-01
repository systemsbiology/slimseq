require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCellsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
    
    Sample.stub!(:find).and_return([mock_model(Sample)])
  end

  def mock_flow_cell(stubs={})
    @mock_flow_cell ||= mock_model(FlowCell, stubs)
  end
  
  describe "responding to GET index" do

    before(:each) do
      @flow_cell_1 = mock_model(FlowCell)
      @flow_cell_2 = mock_model(FlowCell)
      @flow_cells = [@flow_cell_1, @flow_cell_2]
    end
    
    it "should expose all flow_cells as @flow_cells" do
      FlowCell.should_receive(:find).with(:all, {:order=>"date_generated DESC"}).and_return(@flow_cells)
      get :index
      assigns[:flow_cells].should == @flow_cells
    end

    describe "with mime type of xml" do
  
      it "should render all flow_cells as xml" do
        @flow_cell_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @flow_cell_2.should_receive(:summary_hash).and_return( {:n => 2} )
        request.env["HTTP_ACCEPT"] = "application/xml"
        FlowCell.should_receive(:find).with(:all, {:order=>"date_generated DESC"}).and_return(@flow_cells)
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  " +
          "<record>\n    <n type=\"integer\">1</n>\n  </record>\n  <record>\n    " +
          "<n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end
    
    end

    describe "with mime type of json" do
  
      it "should render flow cell summaries as json" do
        @flow_cell_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @flow_cell_2.should_receive(:summary_hash).and_return( {:n => 2} )
        request.env["HTTP_ACCEPT"] = "application/json"
        FlowCell.should_receive(:find).with(:all, {:order=>"date_generated DESC"}).
          and_return(@flow_cells)
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
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
        flow_cell = mock_model(FlowCell)
        flow_cell.should_receive(:detail_hash).and_return( {:n => 1} )
        
        request.env["HTTP_ACCEPT"] = "application/xml"
        FlowCell.should_receive(:find).with("37").and_return(flow_cell)
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  "+
          "<n type=\"integer\">1</n>\n</hash>\n"
      end

    end

    describe "with mime type of json" do
  
      it "should render the flow cell detail as json" do
        flow_cell = mock_model(FlowCell)
        flow_cell.should_receive(:detail_hash).and_return( {:n => 1} )
        
        request.env["HTTP_ACCEPT"] = "application/json"
        FlowCell.should_receive(:find).with("37").and_return(flow_cell)
        get :show, :id => 37
        response.body.should == "{\"n\":1}"
      end
    
    end
    
  end

  describe "responding to GET new" do
    before(:each) do
      @flow_cell = mock_flow_cell
      FlowCell.should_receive(:new).and_return(@flow_cell)
      @flow_cell_lanes = [mock_model(FlowCellLane),mock_model(FlowCellLane)]
      @flow_cell.stub!(:flow_cell_lanes).and_return(@flow_cell_lanes)
      @flow_cell_lane = mock_model(FlowCellLane)
      @actual_reads = mock("Actual Reads Array", :build => true)
      @flow_cell_lane.stub!(:actual_reads).and_return(@actual_reads)
      @flow_cell_lanes.stub!(:build).and_return(@flow_cell_lane)
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

    describe "with a clustered flow cell" do
      before(:each) do
        @flow_cell = mock_flow_cell
        @flow_cell.should_receive(:status).and_return("clustered")
        @flow_cell.stub!(:destroy)
        FlowCell.should_receive(:find).with("37").and_return(@flow_cell)
      end
      
      it "should destroy the requested flow_cell" do        
        @flow_cell.should_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect to the flow_cells list" do
        delete :destroy, :id => "37"
        response.should redirect_to(flow_cells_url)
      end
    
    end

    describe "with a sequenced flow cell" do
      before(:each) do
        @flow_cell = mock_flow_cell
        @flow_cell.should_receive(:status).and_return("sequenced")
        FlowCell.should_receive(:find).with("37").and_return(@flow_cell)
      end
      
      it "should not destroy the requested flow_cell" do        
        @flow_cell.should_not_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect to the flow_cells list" do
        delete :destroy, :id => "37"
        response.should redirect_to(flow_cells_url)
      end
    
    end
    
  end

end
