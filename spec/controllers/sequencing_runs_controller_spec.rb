require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SequencingRunsController do
  include CASAuthenticatedSpecHelper

  before(:each) do
    login_as_user
    
    FlowCell.stub!(:find_all_by_status).and_return([mock_model(FlowCell)])
    Instrument.stub!(:find).and_return([mock_model(Instrument)])
    
    # deal with named scope
    mock_scope = mock("Named Scope")
    Instrument.stub!(:active).and_return(mock_scope)
    mock_scope.stub!(:find).and_return([mock_model(Instrument)])
  end
  
  def mock_sequencing_run(stubs={})
    @mock_sequencing_run ||= mock_model(SequencingRun, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all sequencing_runs as @sequencing_runs" do
      SequencingRun.should_receive(:find).with(:all, :order => "date DESC",
        :include=>["flow_cell", "instrument"]).and_return([mock_sequencing_run])
      get :index
      assigns[:sequencing_runs].should == [mock_sequencing_run]
    end

    describe "with mime type of xml" do
  
      it "should render all sequencing_runs as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        SequencingRun.should_receive(:find).with(:all, :order => "date DESC",
          :include=>["flow_cell", "instrument"]).and_return(sequencing_runs = mock("Array of SequencingRuns"))
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

      before(:each) do
        SequencingRun.stub!(:new).and_return(mock_sequencing_run(:save => true))
        Notifier.stub!(:deliver_sequencing_run_notification)
      end
      
      it "should expose a newly created sequencing_run as @sequencing_run" do
        SequencingRun.should_receive(:new).with({'these' => 'params'}).and_return(mock_sequencing_run(:save => true))
        post :create, :sequencing_run => {:these => 'params'}
        assigns(:sequencing_run).should equal(mock_sequencing_run)
      end

      it "should redirect to the created sequencing_run" do
        post :create, :sequencing_run => {}
        response.should redirect_to(sequencing_runs_url)
      end
      
      it "should send email notifications" do
        Notifier.should_receive(:deliver_sequencing_run_notification)
        post :create, :sequencing_run => {}
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
        response.should redirect_to(sequencing_runs_url)
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

    describe "with no pipeline results" do
      before(:each) do
        @sequencing_run = mock_sequencing_run
        SequencingRun.should_receive(:find).with("37").and_return(@sequencing_run)
        @sequencing_run.should_receive(:pipeline_results).and_return([])
        @sequencing_run.stub!(:destroy)
      end
      
      it "should destroy the requested sequencing_run" do
        @sequencing_run.should_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect to the sequencing_runs list" do
        delete :destroy, :id => "37"
        response.should redirect_to(sequencing_runs_url)
      end
    end
    
    describe "with pipeline results" do
      before(:each) do
        @sequencing_run = mock_sequencing_run
        SequencingRun.should_receive(:find).with("37").and_return(@sequencing_run)
        @sequencing_run.should_receive(:pipeline_results).and_return(["result 1", "result 2"])
      end
      
      it "should destroy the requested sequencing_run" do
        @sequencing_run.should_not_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect to the sequencing_runs list" do
        delete :destroy, :id => "37"
        response.should redirect_to(sequencing_runs_url)
      end
    end
    
  end

  describe "responding to GET default_output_paths" do
    before(:each) do
      @sequencing_run = mock_sequencing_run
      SequencingRun.stub!(:find).and_return(@sequencing_run)
    end

    it "should find the requested sequencing run" do
      SequencingRun.should_receive(:find).with("37").and_return(@sequencing_run)
      get :default_output_paths, :id => 37
    end

    it "should render the default_output_paths template" do
      get :default_output_paths, :id => 37
      response.should render_template('default_output_paths')
    end
  end
end
