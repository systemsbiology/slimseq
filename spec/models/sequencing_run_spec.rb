require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SequencingRun do
  it "should mark the flow cell associated with a sequencing run being created as sequenced" do
    @flow_cell = mock_model(FlowCell)
    @flow_cell.should_receive(:sequence!).and_return(true)
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
  end

  it "should mark the flow cell associated with a sequencing run being destroyed as clustered" do
    @flow_cell = mock_model(FlowCell)
    @flow_cell.stub!(:sequence!).and_return(true)
    @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
    
    @flow_cell.should_receive(:unsequence!).and_return(true)
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
    @sequencing_run.run_name.should == "081010_HWI-EAS124_456DEF"
  end
end
