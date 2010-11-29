require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSetsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
    
    projects = [mock_model(Project), mock_model(Project)]
    Project.stub!(:accessible_to_user).and_return(projects)
    NamingScheme.stub!(:find).and_return(
      [mock_model(NamingScheme), mock_model(NamingScheme)]
    )
    SamplePrepKit.stub!(:find).and_return(
      [mock_model(SamplePrepKit), mock_model(SamplePrepKit)]
    )
    ReferenceGenome.stub!(:find).and_return(
      [mock_model(ReferenceGenome), mock_model(ReferenceGenome)]
    )
  end
    
  describe "#new" do
    def do_get
      get :new
    end

    it "is successful" do
      do_get
      response.should be_success
    end

    it "renders the new template" do
      do_get
      response.should render_template('new')
    end
  end
  
  describe "#create" do
    before(:each) do
      @sample_set = mock_model(SampleSet)
      SampleSet.stub!(:parse_api).and_return(@sample_set)
    end

    context "with a valid sample set" do
      before(:each) do
        @sample_set.stub!(:save).and_return(true)
      end
  
      def do_post
        post :create, :sample_set => {}
      end
  
      it "should make a new sample set from the form parameters" do
        SampleSet.should_receive(:parse_api).and_return(@sample_set)
        do_post
      end
      
      it "successfully saves the new sample set" do
        @sample_set.should_receive(:save).and_return(true)
        do_post
      end

      it "" do
        do_post
        response.status.should == "200 OK"
      end
      
    end
    
    context "with an invalid sample set" do
      before(:each) do
        @sample_set.stub!(:save).and_return(false)
        @sample_set.stub!(:error_message).and_return("Error with sample set")
      end

      def do_post
        post :create, :sample_set => {}
      end

      it "does not save the new sample set" do
        @sample_set.should_receive(:save).and_return(false)
        do_post
      end

      it "provides an unprocessable response with an error message" do
        do_post
        response.status.should == "422 Unprocessable Entity"
      end
    end
  end

end
