require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PipelineResult do

  describe "importing the run summary" do

    before(:all) do
      @lane_1 = create_flow_cell_lane
      @lane_2 = create_flow_cell_lane
      @sequencing_run = create_sequencing_run
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
      
    end
  end
end
