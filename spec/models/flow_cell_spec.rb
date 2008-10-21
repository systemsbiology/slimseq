require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCell do
  fixtures :samples, :flow_cells, :flow_cell_lanes
  
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

  it "should update existing lanes from a set of attributes" do
    flow_cell = flow_cells(:flow_cell_1)
    flow_cell.existing_lane_attributes = {
      flow_cell_lanes(:lane_1).id.to_s => {"starting_concentration"=>"234",
                                      "loaded_concentration"=>"987",
                                      "sample_ids"=>samples(:sample3).id.to_s, "lane_number"=>"1"},
      flow_cell_lanes(:lane_2).id.to_s => {"starting_concentration"=>"0987",
                                      "loaded_concentration"=>"089",
                                      "sample_ids"=>samples(:sample4).id.to_s, "lane_number"=>"2"}
    }
    
    flow_cell.flow_cell_lanes[1].starting_concentration.should == "234"
    flow_cell.flow_cell_lanes[0].starting_concentration.should == "0987"
  end
  
  it "should change associated lane and sample statuses to 'clustered' after creation of flow cell" do
    create_flow_cell
    Sample.find(@sample_1.id).status.should == "clustered"
    Sample.find(@sample_2.id).status.should == "clustered"
    lanes = @flow_cell.flow_cell_lanes
    lanes[0].status.should == "clustered"
    lanes[1].status.should == "clustered"
  end

  it "should change associated sample statuses to 'submitted' after destroying flow cell" do
    create_flow_cell
    @flow_cell.destroy
    Sample.find(@sample_1.id).status.should == "submitted"
    Sample.find(@sample_2.id).status.should == "submitted"
  end
  
  def create_flow_cell
    @flow_cell = FlowCell.new(:name => "flobot", :date_generated => '2008-10-07')
    @sample_1 = samples(:sample5)
    @sample_2 = samples(:sample6)
    @flow_cell.flow_cell_lanes.build(:sample_ids => [@sample_1.id], :lane_number => 1,
      :starting_concentration => 1234, :loaded_concentration => 2)
    @flow_cell.flow_cell_lanes.build(:sample_ids => [@sample_2.id], :lane_number => 2,
      :starting_concentration => 4232, :loaded_concentration => 2)
    @flow_cell.save!
  end
end
