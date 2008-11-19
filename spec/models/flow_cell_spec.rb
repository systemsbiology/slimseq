require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCell do
  fixtures :site_config
  
  it "should build new lanes from a set of attributes" do
    flow_cell = FlowCell.new
    flow_cell_lanes = [FlowCellLane.new,FlowCellLane.new]
    flow_cell.should_receive(:flow_cell_lanes).twice.and_return(flow_cell_lanes)
    flow_cell_lanes.should_receive(:build).exactly(2).times
    flow_cell.new_lane_attributes = [
      {"starting_concentration"=>"234", "loaded_concentration"=>"987",
       "sample_ids"=>"7", "lane_number"=>"1"},
      {"starting_concentration"=>"0987", "loaded_concentration"=>"089",
       "sample_ids"=>"8", "lane_number"=>"2"}
    ]
  end

  describe "updating existing lanes from a set of attributes" do
    fixtures :samples, :flow_cells, :flow_cell_lanes
    
    it "should update the attributes" do
      flow_cell = flow_cells(:flow_cell_1)
      flow_cell.existing_lane_attributes = {
        flow_cell_lanes(:lane_1).id.to_s => {"starting_concentration"=>"234",
                                        "loaded_concentration"=>"987",
                                        "sample_ids"=>samples(:sample3).id.to_s, "lane_number"=>"1"},
        flow_cell_lanes(:lane_2).id.to_s => {"starting_concentration"=>"0987",
                                        "loaded_concentration"=>"089",
                                        "sample_ids"=>samples(:sample4).id.to_s, "lane_number"=>"2"}
      }

      FlowCellLane.find(flow_cell_lanes(:lane_1).id).starting_concentration.should == "234"
      FlowCellLane.find(flow_cell_lanes(:lane_2).id).starting_concentration.should == "0987"
    end
  end
  
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
      :name => "20WERT",
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
    
    flow_cell.detail_hash.should == {
      :id => flow_cell.id,
      :name => "20WERT",
      :date_generated => Date.today,
      :updated_at => flow_cell.updated_at,
      :comment => "failed",
      :status => "clustered"
    }
  end
end
