require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SequencingRun do
  fixtures :samples, :flow_cells, :flow_cell_lanes, :instruments
  
  it "should change associated sample statuses to 'sequenced' after creation of sequencing run" do
    create_sequencing_run
    FlowCell.find(flow_cells(:flow_cell_1).id).status.should == "sequenced"
    Sample.find(samples(:sample5).id).status.should == "sequenced"
    Sample.find(samples(:sample6).id).status.should == "sequenced"
  end

  it "should change associated sample statuses to 'submitted' after destroying flow cell" do
    create_sequencing_run
    @sequencing_run.destroy
    FlowCell.find(flow_cells(:flow_cell_1).id).status.should == "clustered"
    Sample.find(samples(:sample5).id).status.should == "clustered"
    Sample.find(samples(:sample6).id).status.should == "clustered"
  end
  
  def create_sequencing_run
    @sequencing_run = SequencingRun.create(:date => '2008-10-10',
                                           :flow_cell_id => flow_cells(:flow_cell_1).id,
                                           :instrument_id => instruments(:sequence_master_3000).id
                                          )
  end
end
