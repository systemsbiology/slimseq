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
    before(:each) do
      @sample_set = mock_model(SampleSet)
      SampleSet.stub!(:new).and_return(@sample_set)
    end

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

    it "makes an new sample set" do
      SampleSet.should_receive(:new).and_return(@sample_set)
      do_get
    end

    it "does not save the new sample set" do
      @sample_set.should_not_receive(:save)
      do_get
    end

    it "assigns the new sample set for the view" do
      do_get
      assigns[:sample_set].should equal(@sample_set)
    end      
  end
  
  describe "#create" do
    before(:each) do
      @sample_set = mock_model(SampleSet)
      SampleSet.stub!(:parse_form).and_return(@sample_set)
    end

    context "with a valid sample set" do
      before(:each) do
        @sample_set.stub!(:save).and_return(true)
      end
  
      def do_post
        post :create, :sample_set => {}
      end
  
      it "should make a new sample set from the form parameters" do
        SampleSet.should_receive(:parse_form).and_return(@sample_set)
        do_post
      end
      
      it "successfully saves the new sample set" do
        @sample_set.should_receive(:save).and_return(true)
        do_post
      end

      it "should redirect to the list of samples" do
        do_post
        response.should redirect_to(samples_url)
      end
      
    end
    
    context "with an invalid sample set" do
      before(:each) do
        @sample_set.stub!(:save).and_return(false)
      end

      def do_post
        post :create, :sample_set => {}
      end

      it "does not save the new sample set" do
        @sample_set.should_receive(:save).and_return(false)
        do_post
      end

      it "re-renders the 'new' template" do
        do_post
        response.should render_template('new')
      end
    end
  end

  describe "handling POST /sample_sets with a JSON mime type" do
    it "should create the samples when valid parameters are given" do
      sample_set = mock_model(SampleSet)
      SampleSet.should_receive(:parse_api).with(
        {"naming_scheme_id" => "12",
        "sample_prep_kit_id" => "4",
        "reference_genome_id" => "7",
        "project_id" => "43",
        "alignment_start_position" => "1",
        "alignment_end_position" => "36",
        "desired_read_length" => "36",
        "eland_parameter_set_id" => "3",
        "budget_number" => "12345678",
        "submitted_by" => "jsmith",
        "samples" => [
          { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Key" => "YO 1" },
          { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 2" },
        ]}
      ).and_return(sample_set)
      sample_set.should_receive(:save).and_return(true)

      request.env["HTTP_ACCEPT"] = "application/json"

      post :create, :sample_set => {
        "naming_scheme_id" => "12",
        "sample_prep_kit_id" => "4",
        "reference_genome_id" => "7",
        "project_id" => "43",
        "alignment_start_position" => "1",
        "alignment_end_position" => "36",
        "desired_read_length" => "36",
        "eland_parameter_set_id" => "3",
        "budget_number" => "12345678",
        "samples" => [
          { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Key" => "YO 1" },
          { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 2" }
        ] }
    end
  end

end
