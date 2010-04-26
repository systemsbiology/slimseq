require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SequencingRun do
  fixtures :site_config

  it "should mark the flow cell associated with a sequencing run being created as sequenced" do
    @flow_cell = mock_model(FlowCell, :destroyed? => false)
    @flow_cell.should_receive(:sequence!).and_return(true)
    @flow_cell.stub!(:sequencing_runs).and_return([create_sequencing_run])
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
  end

  it "should mark the flow cell associated with a sequencing run being destroyed as clustered" do
    @flow_cell = mock_model(FlowCell, :destroyed? => false)
    @flow_cell.stub!(:sequence!).and_return(true)
    @flow_cell.stub!(:sequencing_runs).and_return([create_sequencing_run])
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
    
    @flow_cell.should_receive(:unsequence!).and_return(true)
    @sequencing_run.destroy
  end
  
  it "should leave the flow cell associated with a sequencing run being destroyed as sequenced " +
     "if there is another sequencing run associated with this flow cell" do
    @flow_cell = mock_model(FlowCell, :destroyed? => false)
    @flow_cell.stub!(:sequence!).and_return(true)
    @flow_cell.stub!(:sequencing_runs).and_return([
        create_sequencing_run, create_sequencing_run
      ])
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)

    @flow_cell.should_not_receive(:unsequence!)
    @sequencing_run.destroy
  end
  
  it "should provide the formatted date" do
    @sequencing_run = create_sequencing_run(:date => "2008-10-10")
    @sequencing_run.date_yymmdd.should == "081010"
  end
  
  describe "providing the 'run name'" do
    it "should include the run number if available" do
      @instrument = create_instrument(:serial_number => "HWI-EAS124")
      @flow_cell = create_flow_cell(:name => "456DEF")
      @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
        :flow_cell => @flow_cell, :run_number => 80)
      @sequencing_run.run_name.should == "081010_HWI-EAS124_0080_FC456DEF"
    end

    it "should exclude the run number if unavailable" do
      @instrument = create_instrument(:serial_number => "HWI-EAS124")
      @flow_cell = create_flow_cell(:name => "456DEF")
      @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
        :flow_cell => @flow_cell)
      @sequencing_run.run_name.should == "081010_HWI-EAS124_FC456DEF"
    end
  end
  
  it "should mark the newest run as 'best', others as not the best" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run_1 = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    @sequencing_run_2 = create_sequencing_run(:date => "2008-10-12", :instrument => @instrument,
      :flow_cell => @flow_cell)

    @sequencing_run_1.reload.best.should == false
    @sequencing_run_2.best.should == true
  end
  
  it "should mark a run as 'best', others as not the best" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run_1 = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    @sequencing_run_2 = create_sequencing_run(:date => "2008-10-12", :instrument => @instrument,
      :flow_cell => @flow_cell)

    @sequencing_run_1.reload.update_attributes(:best => true)
    
    @sequencing_run_1.reload.best.should == true
    @sequencing_run_2.reload.best.should == false
  end
  
  it "should find a run based on the run name without a run number" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    SequencingRun.find_by_run_name("081010_HWI-EAS124_FC456DEF").should == @sequencing_run
  end
  
  it "should find a run based on the run name with a run number" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell, :run_number => 123)
    SequencingRun.find_by_run_name("081010_HWI-EAS124_0123_FC456DEF").should == @sequencing_run
  end
  
  it "should return nil when finding a run based on the run name that doesn't exist" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    SequencingRun.find_by_run_name("081011_HWI-EAS124_FC456DEF").should == nil
  end
  
  it "should write a config file" do
    GeraldDefaults.destroy_all
    @gerald_defaults = create_gerald_defaults
    @instrument = create_instrument(:serial_number => "HWI-EAS124", :web_root => "http://pipeline1/")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @flow_cell_lane = create_flow_cell_lane(:flow_cell => @flow_cell)
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    
    params = {
      "0" => {
        :lane_number => 1,
        :analysis => "eland_extended",
        :eland_genome => "/path/to/genome",
        :eland_seed_length => 20,
        :eland_max_matches => 1,
        :use_bases => "all"
      },
      "1" => {
        :lane_number => 2,
        :analysis => "eland_extended",
        :eland_genome => "/path/to/another/genome",
        :eland_seed_length => 25,
        :eland_max_matches => 2,
        :use_bases => "Y*n"
      }
    }
    @sequencing_run.write_config_file(params)
    
    f = File.new("tmp/txt/081010_HWI-EAS124_FC456DEF-config.txt")
    
    f.readline.should == "SEQUENCE_FORMAT --fasta\n"
    f.readline.should == "ELAND_MULTIPLE_INSTANCES 8\n"
    f.readline.should == "EMAIL_LIST me@localhost\n"
    f.readline.should == "EMAIL_SERVER localhost\n"
    f.readline.should == "EMAIL_DOMAIN localhost\n"
    f.readline.should == "WEB_DIR_ROOT http://pipeline1/\n"
    f.readline.should == "1:ANALYSIS eland_extended\n"
    f.readline.should == "1:ELAND_GENOME /path/to/genome\n"
    f.readline.should == "1:ELAND_SEED_LENGTH 20\n"
    f.readline.should == "1:ELAND_MAX_MATCHES 1\n"
    f.readline.should == "1:USE_BASES all\n"
    f.readline.should == "2:ANALYSIS eland_extended\n"
    f.readline.should == "2:ELAND_GENOME /path/to/another/genome\n"
    f.readline.should == "2:ELAND_SEED_LENGTH 25\n"
    f.readline.should == "2:ELAND_MAX_MATCHES 2\n"
    f.readline.should == "2:USE_BASES Y*n\n"
  end
  
  it "should provide default gerald params with last base skipping turned off" do
    GeraldDefaults.destroy_all
    @gerald_defaults = create_gerald_defaults
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @sample_mixture_1 = create_sample_mixture
    @sample_mixture_2 = create_sample_mixture
    @sample_1 = create_sample(:sample_mixture => @sample_mixture_1)
    @sample_2 = create_sample(:sample_mixture => @sample_mixture_2)
    @flow_cell = create_flow_cell(:name => "456DEF")
    create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 1, :sample_mixture => @sample_mixture_1)
    create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 2, :sample_mixture => @sample_mixture_2)
    @flow_cell.reload
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    
    expected_params = {
      "0" => {
        :lane_number => 1,
        :analysis => "eland_extended",
        :eland_genome => "/path/to/fasta",
        :eland_seed_length => @gerald_defaults.eland_seed_length,
        :eland_max_matches => @gerald_defaults.eland_max_matches,
        :use_bases => "Y36"
      },
      "1" => {
        :lane_number => 2,
        :analysis => "eland_extended",
        :eland_genome => "/path/to/fasta",
        :eland_seed_length => @gerald_defaults.eland_seed_length,
        :eland_max_matches => @gerald_defaults.eland_max_matches,
        :use_bases => "Y36"
      }
    }
    
    @sequencing_run.default_gerald_params.should == expected_params
  end

  it "should provide default gerald params with last base skipping turned on" do
    GeraldDefaults.destroy_all
    @gerald_defaults = create_gerald_defaults(:skip_last_base => true)
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sample_mixture_1 = create_sample_mixture
    @sample_mixture_2 = create_sample_mixture
    @sample_1 = create_sample(:sample_mixture => @sample_mixture_1)
    @sample_2 = create_sample(:sample_mixture => @sample_mixture_2)
    create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 1, :sample_mixture => @sample_mixture_1)
    create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 2, :sample_mixture => @sample_mixture_2)
    @flow_cell.reload
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    
    expected_params = {
      "0" => {
        :lane_number => 1,
        :analysis => "eland_extended",
        :eland_genome => "/path/to/fasta",
        :eland_seed_length => @gerald_defaults.eland_seed_length,
        :eland_max_matches => @gerald_defaults.eland_max_matches,
        :use_bases => "Y35n1"
      },
      "1" => {
        :lane_number => 2,
        :analysis => "eland_extended",
        :eland_genome => "/path/to/fasta",
        :eland_seed_length => @gerald_defaults.eland_seed_length,
        :eland_max_matches => @gerald_defaults.eland_max_matches,
        :use_bases => "Y35n1"
      }
    }
    
    @sequencing_run.default_gerald_params.should == expected_params
  end

end
