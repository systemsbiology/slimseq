require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PipelineResult do

  describe "importing the run summary" do

    before(:all) do
      @flow_cell = create_flow_cell
      @lane_1 = create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 1)
      @lane_2 = create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 2)
      @sequencing_run = create_sequencing_run(:flow_cell => @flow_cell)
      @result = PipelineResult.new(
        :sequencing_run => @sequencing_run,
        :summary_file => "#{RAILS_ROOT}/spec/fixtures/html/Summary.htm"
      )
      @result.import_run_summary
    end

    it "should record the total run yield" do
      @sequencing_run.reload.yield_kb.should == 1620040
    end

    it "should record per lane quality metrics" do
      @lane_1.reload
      @lane_1.lane_yield_kb.should == 105724
      @lane_1.average_clusters.should == 87513
      @lane_1.percent_pass_filter_clusters.should == 33.89
      @lane_1.percent_align.should == 0.63
      @lane_1.percent_error.should == 10.37

      @lane_2.reload
      @lane_2.lane_yield_kb.should == 182371
      @lane_2.average_clusters.should == 115866
      @lane_2.percent_pass_filter_clusters.should == 44.18
      @lane_2.percent_align.should == 3.98
      @lane_2.percent_error.should == 5.40
    end
  end
end
