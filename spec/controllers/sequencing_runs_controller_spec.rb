require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe SequencingRunsController do
  before(:each) do
    login_as_user
    
    FlowCell.stub!(:find_all_by_status).and_return([mock_model(FlowCell)])
    Instrument.stub!(:find).and_return([mock_model(Instrument)])
  end
  
  def mock_sequencing_run(stubs={})
    @mock_sequencing_run ||= mock_model(SequencingRun, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all sequencing_runs as @sequencing_runs" do
      SequencingRun.should_receive(:find).with(:all).and_return([mock_sequencing_run])
      get :index
      assigns[:sequencing_runs].should == [mock_sequencing_run]
    end

    describe "with mime type of xml" do
  
      it "should render all sequencing_runs as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        SequencingRun.should_receive(:find).with(:all).and_return(sequencing_runs = mock("Array of SequencingRuns"))
        sequencing_runs.should_receive(:to_xml).and_return("generated XML")
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested sequencing_run as @sequencing_run" do
      SequencingRun.should_receive(:find).with("37").and_return(mock_sequencing_run)
      get :show, :id => "37"
      assigns[:sequencing_run].should equal(mock_sequencing_run)
    end
    
    describe "with mime type of xml" do

      it "should render the requested sequencing_run as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        SequencingRun.should_receive(:find).with("37").and_return(mock_sequencing_run)
        mock_sequencing_run.should_receive(:to_xml).and_return("generated XML")
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new sequencing_run as @sequencing_run" do
      SequencingRun.should_receive(:new).and_return(mock_sequencing_run)
      get :new
      assigns[:sequencing_run].should equal(mock_sequencing_run)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested sequencing_run as @sequencing_run" do
      SequencingRun.should_receive(:find).with("37").and_return(mock_sequencing_run)
      get :edit, :id => "37"
      assigns[:sequencing_run].should equal(mock_sequencing_run)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created sequencing_run as @sequencing_run" do
        SequencingRun.should_receive(:new).with({'these' => 'params'}).and_return(mock_sequencing_run(:save => true))
        post :create, :sequencing_run => {:these => 'params'}
        assigns(:sequencing_run).should equal(mock_sequencing_run)
      end

      it "should redirect to the created sequencing_run" do
        SequencingRun.stub!(:new).and_return(mock_sequencing_run(:save => true))
        post :create, :sequencing_run => {}
        response.should redirect_to(sequencing_runs_url)
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved sequencing_run as @sequencing_run" do
        SequencingRun.stub!(:new).with({'these' => 'params'}).and_return(mock_sequencing_run(:save => false))
        post :create, :sequencing_run => {:these => 'params'}
        assigns(:sequencing_run).should equal(mock_sequencing_run)
      end

      it "should re-render the 'new' template" do
        SequencingRun.stub!(:new).and_return(mock_sequencing_run(:save => false))
        post :create, :sequencing_run => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested sequencing_run" do
        SequencingRun.should_receive(:find).with("37").and_return(mock_sequencing_run)
        mock_sequencing_run.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :sequencing_run => {:these => 'params'}
      end

      it "should expose the requested sequencing_run as @sequencing_run" do
        SequencingRun.stub!(:find).and_return(mock_sequencing_run(:update_attributes => true))
        put :update, :id => "1"
        assigns(:sequencing_run).should equal(mock_sequencing_run)
      end

      it "should redirect to the sequencing_run" do
        SequencingRun.stub!(:find).and_return(mock_sequencing_run(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(sequencing_run_url(mock_sequencing_run))
      end

    end
    
    describe "with invalid params" do

      it "should update the requested sequencing_run" do
        SequencingRun.should_receive(:find).with("37").and_return(mock_sequencing_run)
        mock_sequencing_run.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :sequencing_run => {:these => 'params'}
      end

      it "should expose the sequencing_run as @sequencing_run" do
        SequencingRun.stub!(:find).and_return(mock_sequencing_run(:update_attributes => false))
        put :update, :id => "1"
        assigns(:sequencing_run).should equal(mock_sequencing_run)
      end

      it "should re-render the 'edit' template" do
        SequencingRun.stub!(:find).and_return(mock_sequencing_run(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested sequencing_run" do
      SequencingRun.should_receive(:find).with("37").and_return(mock_sequencing_run)
      mock_sequencing_run.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the sequencing_runs list" do
      SequencingRun.stub!(:find).and_return(mock_sequencing_run(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(sequencing_runs_url)
    end

  end

end
