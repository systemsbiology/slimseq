require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe PipelineRunsController do

  describe "POST 'create'" do
    describe "with valid parameters" do
      
      before(:each) do
        login_as_staff
        
        @pipeline_run = mock_model(PipelineRun)
        PipelineRun.stub!(:new).and_return(@pipeline_run)
        @pipeline_run.stub!(:valid?).and_return(true)
        @pipeline_result = mock_model(PipelineResult)
        @pipeline_result.stub!(:save).and_return(true)
        @pipeline_run.stub!(:pipeline_results).and_return([@pipeline_result])        
      end
      
      it "should instantiate a new pipeline run" do
        PipelineRun.should_receive(:new).and_return(@pipeline_run)
        do_post
      end
      
      it "should produce a valid pipeline run" do
        @pipeline_run.should_receive(:valid?).and_return(true)
        do_post
      end
      
      it "should retrieve the pipeline results under the pipeline run" do
        @pipeline_run.should_receive(:pipeline_results).and_return([@pipeline_result])
        do_post
      end
      
      it "should save the pipeline results" do
        @pipeline_result.stub!(:save).and_return(true)
        do_post
      end
      
      it "should be successful" do
        do_post
        response.should be_success
      end
      
      def do_post
        post :create,
          :run_folder => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
          :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
            "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm",
          :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
            "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt"
      end
      
    end
    
    describe "with invalid parameters" do
      
      before(:each) do
        login_as_staff
        
        @pipeline_run = mock_model(PipelineRun)
        PipelineRun.stub!(:new).and_return(@pipeline_run)
        @pipeline_run.stub!(:valid?).and_return(false)
      end
      
      it "should instantiate a new pipeline run" do
        PipelineRun.should_receive(:new).and_return(@pipeline_run)
        do_post
      end
      
      it "should produce an ivalid pipeline run" do
        @pipeline_run.should_receive(:valid?).and_return(false)
        do_post
      end
      
      it "should be unprocessable" do
        do_post
        response.headers["Status"].should == "422 Unprocessable Entity"
      end
      
      def do_post
        post :create
      end
    end
  end
end
