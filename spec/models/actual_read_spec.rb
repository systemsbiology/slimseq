require 'spec_helper'

describe ActualRead do

  it "provides its matching desired read" do
    mixture = new_sample_mixture
    desired_read = mixture.desired_reads.first

    lane = create_flow_cell_lane(:sample_mixture => mixture)

    lane.actual_reads.first.matching_desired_read.should == desired_read
  end

end
