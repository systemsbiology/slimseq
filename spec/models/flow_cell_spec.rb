require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCell do
  fixtures :site_config
  
  it "should mark the associated flow cell lanes as sequenced when the flow cell is sequenced" do
    flow_cell_lane_1 = create_flow_cell_lane
    flow_cell_lane_2 = create_flow_cell_lane
    flow_cell_lane_1.should_receive(:sequence!).and_return(true)
    flow_cell_lane_2.should_receive(:sequence!).and_return(true)
    flow_cell = create_flow_cell(:flow_cell_lanes => [flow_cell_lane_1, flow_cell_lane_2])
    flow_cell.sequence!
  end
  
  it "should mark the associated flow cell lanes as clustered when the flow cell is 'unsequenced'" do
    flow_cell_lane_1 = create_flow_cell_lane
    flow_cell_lane_2 = create_flow_cell_lane
    flow_cell_lane_1.stub!(:sequence!).and_return(true)
    flow_cell_lane_2.stub!(:sequence!).and_return(true)
    flow_cell = create_flow_cell(:flow_cell_lanes => [flow_cell_lane_1, flow_cell_lane_2])
    flow_cell.sequence!
    
    flow_cell_lane_1.stub!(:unsequence!).and_return(true)
    flow_cell_lane_2.stub!(:unsequence!).and_return(true)
    flow_cell.unsequence!
  end
  
  it "should provide a hash of summary attributes" do
    flow_cell = create_flow_cell(:name => "20WERT")   
    
    flow_cell.summary_hash.should == {
      :id => flow_cell.id,
      :name => "FC20WERT",
      :date_generated => Date.today,
      :updated_at => flow_cell.updated_at,
      :uri => "http://example.com/flow_cells/#{flow_cell.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    flow_cell = create_flow_cell(
      :name => "20WERT",
      :comment => "failed",
      :status => "clustered"
    )
    lane = create_flow_cell_lane(:flow_cell => flow_cell)
    instrument = create_instrument(
      :name => "EAS001",
      :serial_number => "HWI-EAS001",
      :instrument_version => "GAI"
    )
    create_sequencing_run(
      :date => Date.today,
      :flow_cell => flow_cell,
      :instrument => instrument
    )
    
    # reload flow cell to get lane association
    flow_cell.reload
    
    flow_cell.detail_hash.should == {
      :id => flow_cell.id,
      :name => "FC20WERT",
      :date_generated => Date.today,
      :updated_at => flow_cell.updated_at,
      :comment => "failed",
      :status => "sequenced",
      :flow_cell_lane_uris => ["http://example.com/flow_cell_lanes/#{lane.id}"],
      :sequencer => {
        :name => "EAS001",
        :serial_number => "HWI-EAS001",
        :instrument_version => "GAI"
      },
      :sequencer_uri => "http://example.com/instruments/#{instrument.id}"
    }
  end
  
  it "should provide the prefixed flow cell name" do
    flow_cell = create_flow_cell(:name => "20WERT")
    
    flow_cell.prefixed_name.should == "FC20WERT"
  end
end
