require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GeraldConfigurationsController do

  describe "GET 'new'" do
    before(:each) do
      @sequencing_run = mock_model(SequencingRun)
      @flow_cell = mock_model(FlowCell)
      @flow_cell_lanes = [ mock_model(FlowCellLane), mock_model(FlowCellLane) ]
      SequencingRun.stub!(:find).and_return(@sequencing_run)
      @sequencing_run.stub!(:flow_cell).and_return(@flow_cell)
      @sequencing_run.stub!(:run_name).and_return("ASDF_WERT_RTYU")
      @flow_cell.stub!(:flow_cell_lanes).and_return(@flow_cell_lanes)
    end
    
    def do_get
      get :new, :sequencing_run_id => 42
    end
    
    it "should be successful" do
      do_get
      response.should be_success
    end
    
    it "should render the new template" do
      do_get
      response.should render_template('new')      
    end
    
    it "should find the sequencing run" do
      SequencingRun.should_receive(:find).and_return(@sequencing_run)
      do_get
    end

    it "should assign the sequencing run for the view" do
      do_get
      assigns(:sequencing_run).should == @sequencing_run
    end
    
    it "should find the flow cell" do
      @sequencing_run.should_receive(:flow_cell).and_return(@flow_cell)
      do_get
    end

    it "should find the flow cell lanes" do
      @flow_cell.should_receive(:flow_cell_lanes).and_return(@flow_cell_lanes)
      do_get
    end
    
    it "should assign the flow cell lanes for the view" do
      do_get
      assigns(:flow_cell_lanes).should == @flow_cell_lanes
    end
  end

  describe "GET 'create'" do
    before(:each) do
      @sequencing_run = mock_model(SequencingRun)
      SequencingRun.stub!(:find).and_return(@sequencing_run)
      GeraldDefaults.should_receive(:find).and_return( mock_model(GeraldDefaults) )
      @sequencing_run.stub!(:run_name).and_return("ASDF_WERT_RTYU")
      @sequencing_run.stub!(:write_config_file)
      @lanes_hash = {
        "1" => {
          "lane_number" => "1",
          "eland_genome" => "mm9",
          "eland_seed_length" => "20",
          "eland_max_matches" => "1",
          "use_bases" => "all"
        },
        "2" => {
          "lane_number" => "2",
          "eland_genome" => "hs_ref",
          "eland_seed_length" => "25",
          "eland_max_matches" => "2",
          "use_bases" => "Y*n"
        }
      }
    end
             
    def do_post
      post :create, :sequencing_run_id => 42, :lanes => @lanes_hash
    end

    it "should find the sequencing run" do
      SequencingRun.should_receive(:find).and_return(@sequencing_run)
      do_post
    end

    it "should write the config file" do
      @sequencing_run.should_receive(:write_config_file)
      do_post
    end

    it "should assign the lanes param to the view" do
      do_post

      assigns(:lanes).should == @lanes_hash
    end

    it "should be successful" do
      do_post
      response.should be_success
    end

    it "should render the create template" do
      do_post
      response.should render_template('create')      
    end
  end    
  
  describe "GET 'default'" do
    before(:each) do
      @sequencing_run = mock_model(SequencingRun)
      SequencingRun.stub!(:find).and_return(@sequencing_run)
      @sequencing_run.stub!(:run_name).and_return("ASDF_WERT_RTYU")
      @sequencing_run.stub!(:default_gerald_params).and_return(@lanes_hash)
      @sequencing_run.stub!(:write_config_file)
    end

    def do_get
      get :default, :sequencing_run_id => 42
    end

    it "should find the sequencing run" do
      SequencingRun.should_receive(:find).and_return(@sequencing_run)
      do_get
    end

    it "should get the default gerald params" do
      @sequencing_run.should_receive(:default_gerald_params).and_return(@lanes_hash)
      do_get
    end

    it "should write the config file" do
      @sequencing_run.should_receive(:write_config_file)
      do_get
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

#    it "should render the file" do
#      do_get
#      response.should_receive(:render).
#        with(:file => "tmp/txt/081010_HWI-EAS124_FC456DEF-config.txt")
#    end
  end
end
