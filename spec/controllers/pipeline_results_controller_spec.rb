require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe PipelineResultsController do
  
  before(:each) do
    login_as_staff
  end

  describe "GET 'index'" do
    before(:each) do
      @pipeline_results = [ mock_model(PipelineResult), mock_model(PipelineResult) ]
      PipelineResult.stub!(:find).and_return(@pipeline_results)
    end

    it 'should find all the pipeline results' do
      PipelineResult.should_receive(:find).with(
        :all,
        :order => "gerald_date DESC, flow_cell_lanes.lane_number ASC",
        :include => :flow_cell_lane
      ).and_return(@pipeline_results)
      get 'index'
    end

    it 'should assign the pipeline results to the view' do
      get 'index'
      assigns(:pipeline_results).should == @pipeline_results
    end

    it "should be successful" do
      get 'index'
      response.should be_success
    end

    it "should render the index template" do
      get 'index'
      response.should render_template 'index'
    end
  end

  describe "responding to GET edit" do

    it "should expose the requested pipeline_result as @pipeline_result" do
      @pipeline_result = mock_model(PipelineResult)
      PipelineResult.should_receive(:find).with("37").and_return( @pipeline_result )
      get :edit, :id => "37"
      assigns[:pipeline_result].should equal(@pipeline_result)
    end

  end

  describe "handling PUT /pipeline_results/1" do

    before(:each) do
      @pipeline_result = mock_model(PipelineResult, :to_param => "1")
      PipelineResult.stub!(:find).and_return(@pipeline_result)
    end

    describe "with successful update" do

      def do_put
        @pipeline_result.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the pipeline_result requested" do
        PipelineResult.should_receive(:find).with("1").and_return(@pipeline_result)
        do_put
      end

      it "should update the found pipeline_result" do
        do_put
        assigns(:pipeline_result).should equal(@pipeline_result)
      end

      it "should assign the found pipeline_result for the view" do
        do_put
        assigns(:pipeline_result).should equal(@pipeline_result)
      end

      it "should redirect to the pipeline_result index" do
        do_put
        response.should redirect_to(pipeline_results_url)
      end

    end

    describe "with failed update" do

      def do_put
        @pipeline_result.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "responding to DELETE destroy" do

    before(:each) do
      @pipeline_result = mock_model(PipelineResult)
      PipelineResult.should_receive(:find).with("37").and_return(@pipeline_result)
      @pipeline_result.stub!(:destroy)
    end

    it "should destroy the requested pipeline_result" do
      @pipeline_result.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "should redirect to the pipeline_results list" do
      delete :destroy, :id => "37"
      response.should redirect_to(pipeline_results_url)
    end
  end

end
