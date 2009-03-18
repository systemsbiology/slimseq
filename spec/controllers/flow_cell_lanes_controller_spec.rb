require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCellLanesController do
  include AuthenticatedSpecHelper

  def mock_flow_cell_lane(stubs={})
    @mock_flow_cell_lane ||= mock_model(FlowCellLane, stubs)
  end
  
  before(:each) do
    login_as_user
  end
  
  describe "responding to GET index" do

    before(:each) do
      flow_cell_lane_1 = mock_model(FlowCellLane)
      flow_cell_lane_2 = mock_model(FlowCellLane)
      flow_cell_lane_1.should_receive(:summary_hash).and_return( {:n => 1} )
      flow_cell_lane_2.should_receive(:summary_hash).and_return( {:n => 2} )
      @flow_cell_lanes = [flow_cell_lane_1, flow_cell_lane_2]
    end
    
    describe "with mime type of xml" do
  
      it "should render all flow_cell_lanes as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        FlowCellLane.should_receive(:find).with(:all).and_return(@flow_cell_lanes)
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
          "<records type=\"array\">\n  <record>\n    <n type=\"integer\">1</n>\n  " +
          "</record>\n  <record>\n    <n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end
    
    end

    describe "with mime type of json" do
  
      it "should render flow cell lane summaries as json" do

        
        request.env["HTTP_ACCEPT"] = "application/json"
        FlowCellLane.should_receive(:find).with(:all).
          and_return(@flow_cell_lanes)
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end
    
    end

  end

  describe "responding to GET show" do
    
    before(:each) do
      @flow_cell_lane = mock_model(FlowCellLane)
      @flow_cell_lane.should_receive(:detail_hash).and_return( {:n => 1} )      
    end
    
    describe "with mime type of xml" do

      it "should render the requested flow_cell_lane as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        FlowCellLane.should_receive(:find).with("37").and_return(@flow_cell_lane)
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  " +
          "<n type=\"integer\">1</n>\n</hash>\n"
      end

    end
    
    describe "with mime type of json" do
  
      it "should render the flow cell lane detail as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        FlowCellLane.should_receive(:find).with("37").and_return(@flow_cell_lane)
        get :show, :id => 37
        response.body.should == "{\"n\":1}"
      end
    
    end
    
  end

#  describe "responding to GET new" do
#  
#    it "should expose a new flow_cell_lane as @flow_cell_lane" do
#      FlowCellLane.should_receive(:new).and_return(mock_flow_cell_lane)
#      get :new
#      assigns[:flow_cell_lane].should equal(mock_flow_cell_lane)
#    end
#
#  end
#
#  describe "responding to GET edit" do
#  
#    it "should expose the requested flow_cell_lane as @flow_cell_lane" do
#      FlowCellLane.should_receive(:find).with("37").and_return(mock_flow_cell_lane)
#      get :edit, :id => "37"
#      assigns[:flow_cell_lane].should equal(mock_flow_cell_lane)
#    end
#
#  end
#
#  describe "responding to POST create" do
#
#    describe "with valid params" do
#      
#      it "should expose a newly created flow_cell_lane as @flow_cell_lane" do
#        FlowCellLane.should_receive(:new).with({'these' => 'params'}).and_return(mock_flow_cell_lane(:save => true))
#        post :create, :flow_cell_lane => {:these => 'params'}
#        assigns(:flow_cell_lane).should equal(mock_flow_cell_lane)
#      end
#
#      it "should redirect to the created flow_cell_lane" do
#        FlowCellLane.stub!(:new).and_return(mock_flow_cell_lane(:save => true))
#        post :create, :flow_cell_lane => {}
#        response.should redirect_to(flow_cell_lane_url(mock_flow_cell_lane))
#      end
#      
#    end
#    
#    describe "with invalid params" do
#
#      it "should expose a newly created but unsaved flow_cell_lane as @flow_cell_lane" do
#        FlowCellLane.stub!(:new).with({'these' => 'params'}).and_return(mock_flow_cell_lane(:save => false))
#        post :create, :flow_cell_lane => {:these => 'params'}
#        assigns(:flow_cell_lane).should equal(mock_flow_cell_lane)
#      end
#
#      it "should re-render the 'new' template" do
#        FlowCellLane.stub!(:new).and_return(mock_flow_cell_lane(:save => false))
#        post :create, :flow_cell_lane => {}
#        response.should render_template('new')
#      end
#      
#    end
#    
#  end
#
#  describe "responding to PUT udpate" do
#
#    describe "with valid params" do
#
#      it "should update the requested flow_cell_lane" do
#        FlowCellLane.should_receive(:find).with("37").and_return(mock_flow_cell_lane)
#        mock_flow_cell_lane.should_receive(:update_attributes).with({'these' => 'params'})
#        put :update, :id => "37", :flow_cell_lane => {:these => 'params'}
#      end
#
#      it "should expose the requested flow_cell_lane as @flow_cell_lane" do
#        FlowCellLane.stub!(:find).and_return(mock_flow_cell_lane(:update_attributes => true))
#        put :update, :id => "1"
#        assigns(:flow_cell_lane).should equal(mock_flow_cell_lane)
#      end
#
#      it "should redirect to the flow_cell_lane" do
#        FlowCellLane.stub!(:find).and_return(mock_flow_cell_lane(:update_attributes => true))
#        put :update, :id => "1"
#        response.should redirect_to(flow_cell_lane_url(mock_flow_cell_lane))
#      end
#
#    end
#    
#    describe "with invalid params" do
#
#      it "should update the requested flow_cell_lane" do
#        FlowCellLane.should_receive(:find).with("37").and_return(mock_flow_cell_lane)
#        mock_flow_cell_lane.should_receive(:update_attributes).with({'these' => 'params'})
#        put :update, :id => "37", :flow_cell_lane => {:these => 'params'}
#      end
#
#      it "should expose the flow_cell_lane as @flow_cell_lane" do
#        FlowCellLane.stub!(:find).and_return(mock_flow_cell_lane(:update_attributes => false))
#        put :update, :id => "1"
#        assigns(:flow_cell_lane).should equal(mock_flow_cell_lane)
#      end
#
#      it "should re-render the 'edit' template" do
#        FlowCellLane.stub!(:find).and_return(mock_flow_cell_lane(:update_attributes => false))
#        put :update, :id => "1"
#        response.should render_template('edit')
#      end
#
#    end
#
#  end
#
#  describe "responding to DELETE destroy" do
#
#    it "should destroy the requested flow_cell_lane" do
#      FlowCellLane.should_receive(:find).with("37").and_return(mock_flow_cell_lane)
#      mock_flow_cell_lane.should_receive(:destroy)
#      delete :destroy, :id => "37"
#    end
#  
#    it "should redirect to the flow_cell_lanes list" do
#      FlowCellLane.stub!(:find).and_return(mock_flow_cell_lane(:destroy => true))
#      delete :destroy, :id => "1"
#      response.should redirect_to(flow_cell_lanes_url)
#    end
#
#  end

end
