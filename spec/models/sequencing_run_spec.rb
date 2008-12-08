require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SequencingRun do
  it "should mark the flow cell associated with a sequencing run being created as sequenced" do
    @flow_cell = mock_model(FlowCell)
    @flow_cell.should_receive(:sequence!).and_return(true)
    @flow_cell.stub!(:sequencing_runs).and_return([create_sequencing_run])
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
  end

  it "should mark the flow cell associated with a sequencing run being destroyed as clustered" do
    @flow_cell = mock_model(FlowCell)
    @flow_cell.stub!(:sequence!).and_return(true)
    @flow_cell.stub!(:sequencing_runs).and_return([create_sequencing_run])
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
    
    @flow_cell.should_receive(:unsequence!).and_return(true)
    @sequencing_run.destroy
  end
  
  it "should leave the flow cell associated with a sequencing run being destroyed as sequenced " +
     "if there is another sequencing run associated with this flow cell" do
    @flow_cell = mock_model(FlowCell)
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
  
  it "should provide the 'run name'" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    @sequencing_run.run_name.should == "081010_HWI-EAS124_FC456DEF"
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
  
  it "should find a run based on the run name" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    SequencingRun.find_by_run_name("081010_HWI-EAS124_FC456DEF").should == @sequencing_run
  end
  
  it "should return nil when finding a run based on the run name that doesn't exist" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    SequencingRun.find_by_run_name("081011_HWI-EAS124_FC456DEF").should == nil
  end
  
  it "should write a config file" do
    @instrument = create_instrument(:serial_number => "HWI-EAS124")
    @flow_cell = create_flow_cell(:name => "456DEF")
    @flow_cell_lane = create_flow_cell_lane(:flow_cell => @flow_cell)
    @sequencing_run = create_sequencing_run(:date => "2008-10-10", :instrument => @instrument,
      :flow_cell => @flow_cell)
    
    params = {
      "0" => {
        :lane_number => 1,
        :eland_genome => "/path/to/genome",
        :eland_seed_length => 20,
        :eland_max_matches => 1,
        :use_bases => "all"
      },
      "1" => {
        :lane_number => 2,
        :eland_genome => "/path/to/another/genome",
        :eland_seed_length => 25,
        :eland_max_matches => 2,
        :use_bases => "Y*n"
      }
    }
    @sequencing_run.write_config_file(params)
    
    f = File.new("tmp/txt/081010_HWI-EAS124_FC456DEF-config.txt")
    
    f.readline.should == "ANALYSIS eland_extended\n"
    f.readline.should == "SEQUENCE_FORMAT --fasta\n"
    f.readline.should == "ELAND_MULTIPLE_INSTANCES 8\n"
    f.readline.should == "QF_PARAMS '(NEIGHBOUR >=2.0) && (CHASTITY >= 0.6)'\n"
    f.readline.should == "1:ELAND_GENOME /path/to/genome\n"
    f.readline.should == "1:ELAND_SEED_LENGTH 20\n"
    f.readline.should == "1:ELAND_MAX_MATCHES 1\n"
    f.readline.should == "1:USE_BASES all\n"
    f.readline.should == "2:ELAND_GENOME /path/to/another/genome\n"
    f.readline.should == "2:ELAND_SEED_LENGTH 25\n"
    f.readline.should == "2:ELAND_MAX_MATCHES 2\n"
    f.readline.should == "2:USE_BASES Y*n\n"
  end
end
