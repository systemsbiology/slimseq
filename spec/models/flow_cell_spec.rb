require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCell do
  describe "setting lane attributes" do
    it "should build lanes from a set of attributes" do
      @flow_cell = FlowCell.new
      @flow_cell_lanes = [FlowCellLane.new,FlowCellLane.new]
      @flow_cell.should_receive(:flow_cell_lanes).twice.and_return(@flow_cell_lanes)
      @flow_cell_lanes.should_receive(:build).exactly(2).times
      @flow_cell.lane_attributes = [
        {"starting_concentration"=>"234", "loaded_concentration"=>"987",
         "sample_id"=>"7", "lane_number"=>"1"},
        {"starting_concentration"=>"0987", "loaded_concentration"=>"089",
         "sample_id"=>"8", "lane_number"=>"2"}
      ]
    end
  end
end
