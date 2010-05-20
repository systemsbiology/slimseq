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
    
  describe "handling GET /sample_sets/new" do
    describe "step 1" do
      before(:each) do
        @sample_set = mock_model(SampleSet)
        SampleSet.stub!(:new).and_return(@sample_set)
      end

      def do_get
        get :new
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should render new template" do
        do_get
        response.should render_template('new')
      end

      it "should create an new sample_set" do
        SampleSet.should_receive(:new).and_return(@sample_set)
        do_get
      end

      it "should not save the new sample_set" do
        @sample_set.should_not_receive(:save)
        do_get
      end

      it "should assign the new sample_set for the view" do
        do_get
        assigns[:sample_set].should equal(@sample_set)
      end      
    end
    
    describe "step 2" do
      before(:each) do
        @sample_set = mock_model(SampleSet)
        SampleSet.stub!(:new).and_return(@sample_set)
      end
      
      def do_get
        get :new, :step => "2", :sample_set => { :number_of_samples => 2 }
      end
      
      describe "with invalid sample set data" do
        before(:each) do
          @sample_set.stub!(:valid?).and_return(false)
        end
        
        it "should create an new sample_set" do
          SampleSet.should_receive(:new).and_return(@sample_set)
          do_get
        end
        
        it "should check the validity of the sample set" do
          @sample_set.should_receive(:valid?).and_return(false)
          do_get
        end
        
        it "should be successful" do
          do_get
          response.should be_success
        end

        it "should render new template" do
          do_get
          response.should render_template('new')
        end
      end
      
      describe "with valid sample set data" do
        before(:each) do
          @lab_group_profile = mock_model(LabGroupProfile, :samples_need_approval => true)
          @lab_group = mock_model(LabGroup, :lab_group_profile => @lab_group_profile) 
          @project = mock_model(Project, :lab_group => @lab_group)

          @sample_mixture_1 = mock_model(SampleMixture)
          @sample_mixture_2 = mock_model(SampleMixture)
          @sample_mixtures = [@sample_mixture_1, @sample_mixture_2]

          @sample_set.stub!(:valid?).and_return(true)
          @sample_set.stub!(:sample_mixtures).and_return(@sample_mixturess)
          @sample_set.stub!(:project).and_return(@project)
        end

        describe "without a naming scheme" do
          before(:each) do
            @sample_set.stub!(:naming_scheme).and_return(nil)
            @sample_set.stub!(:naming_scheme_id).and_return(nil)
          end

          it "should create an new sample_set" do
            SampleSet.should_receive(:new).and_return(@sample_set)
            do_get
          end
          
          it "should check the validity of the sample set" do
            @sample_set.should_receive(:valid?).and_return(true)
            do_get
          end

          it "should assign whether samples need approval to the view" do
            do_get
            assigns[:samples_need_approval].should == true
          end

          it "should be successful" do
            do_get
            response.should be_success
          end

          it "should render new template" do
            do_get
            response.should render_template('new')
          end

          it "should not save the new sample_set" do
            @sample_set.should_not_receive(:save)
            do_get
          end

          it "should assign the new sample_set for the view" do
            do_get
            assigns[:sample_set].should equal(@sample_set)
          end
        end

        describe "with a naming scheme" do
          before(:each) do
            @naming_scheme = mock_model(NamingScheme)
            @sample_set.stub!(:naming_scheme).and_return(@naming_scheme)
            @sample_set.stub!(:naming_scheme_id).and_return(1)
            @naming_scheme.stub!(:ordered_naming_elements).and_return(
              [mock_model(NamingElement), mock_model(NamingElement)]
            )
            NamingScheme.stub!(:find).and_return(nil)
          end
          
          it "should create an new sample_set" do
            SampleSet.should_receive(:new).and_return(@sample_set)
            do_get
          end
          
          it "should check the validity of the sample set" do
            @sample_set.should_receive(:valid?).and_return(true)
            do_get
          end

          it "should be successful" do
            do_get
            response.should be_success
          end

          it "should render new template" do
            do_get
            response.should render_template('new')
          end

          it "should not save the new sample_set" do
            @sample_set.should_not_receive(:save)
            do_get
          end

          it "should assign the new sample_set for the view" do
            do_get
            assigns[:sample_set].should equal(@sample_set)
          end
        end
      end
    end
  end
  
  describe "handling POST /sample_sets with HTML mime type" do
    before(:each) do
      @lab_group = mock_model(LabGroup)
      @project = mock_model(Project, :lab_group => @lab_group)
      @sample_set = mock_model(SampleSet, :to_param => "1", :project => @project)
      SampleSet.stub!(:new).and_return(@sample_set)
      @sample = mock_model(Sample)
      Sample.stub!(:new).and_return(@sample)
      @sample_set.stub!(:sample_mixtures).and_return([mock_model(SampleMixture)])
      Notifier.stub!(:deliver_sample_submission_notification)
    end
   
    describe "with a valid sample set" do
      before(:each) do
        @sample_set.stub!(:save).and_return(true)
      end
  
      def do_post
        post :create,
          :sample_set => {
            "submission_date(2i)"=>"10", "naming_scheme_id"=>"",
            "sample_prep_kit_id"=>"1", "number_of_samples"=>"2",
            "submission_date(3i)"=>"6", "alignment_end_position"=>"18",
            "desired_read_length"=>"18", "reference_genome_id"=>"2",
            "alignment_start_position"=>"1", "lab_group_id"=>"1",
            "budget_number"=>"1234", "insert_size"=>"150",
            "submission_date(1i)"=>"2008",
            "sample_mixtures" => {
              "0"=>{
                "name_on_tube"=>"1121",
                "sample_description" => "Sample 1121",
                "samples" => {
                  "0" => {
                    "schemed_name"=>{
                      "Protocol"=>"203", "Cell Type"=>"197", "Time"=>"184",
                      "Biological Replicate"=>"", "Antibody"=>"291", "Stimulus"=>"189",
                      "Exclude From Analysis"=>"204", "Technical Replicate"=>"202", "Date"=>""
                    }
                  }
                }
              }
            }
          }
      end
  
      it "should create a new sample_set that" do
        SampleSet.should_receive(:new).and_return(@sample_set)
        do_post
      end
      
      it "should save the sample set" do
        @sample_set.should_receive(:save).and_return(true)
        do_post
      end      

      it "should redirect to the list of samples" do
        do_post
        response.should redirect_to(samples_url)
      end
      
    end
    
    describe "with an invalid sample set" do
      before(:each) do
        @sample_set.stub!(:save).and_return(false)
        @naming_scheme = mock_model(NamingScheme)
        @sample_set.stub!(:naming_scheme).and_return(@naming_scheme)
        @naming_scheme.stub!(:ordered_naming_elements).and_return( [mock_model(NamingElement)] )
      end

      def do_post
        post :create,
          :sample_set => {
            "submission_date(2i)"=>"10", "naming_scheme_id"=>"",
            "sample_prep_kit_id"=>"1", "number_of_samples"=>"2",
            "submission_date(3i)"=>"6", "alignment_end_position"=>"18",
            "desired_read_length"=>"18", "reference_genome_id"=>"2",
            "alignment_start_position"=>"1", "lab_group_id"=>"1",
            "budget_number"=>"1234", "insert_size"=>"150",
            "submission_date(1i)"=>"2008",
            "sample_mixtures" => {
              "0"=>{
                "name_on_tube"=>"1121",
                "sample_description" => "Sample 1121",
                "samples" => {
                  "0" => {
                    "schemed_name"=>{
                      "Protocol"=>"203", "Cell Type"=>"197", "Time"=>"184",
                      "Biological Replicate"=>"", "Antibody"=>"291", "Stimulus"=>"189",
                      "Exclude From Analysis"=>"204", "Technical Replicate"=>"202", "Date"=>""
                    }
                  }
                }
              }
            }
          }
      end

      it "should not save the new sample set" do
        @sample_set.should_receive(:save).and_return(false)
        do_post
      end

      it "should get the naming scheme for the sample set" do
        @sample_set.should_receive(:naming_scheme).and_return(@naming_scheme)
        do_post
      end
      
      it "should get the naming elements for the naming scheme" do
        @naming_scheme.should_receive(:ordered_naming_elements).and_return( [mock_model(NamingElement)] )
        do_post
      end
      
      it "should set the step parameter to go to step 2" do
        do_post
        params[:step].should == "2"
      end
  
      it "should re-render 'new' template at step 2" do
        do_post
        response.should render_template('new')
      end
    end
  end

  describe "handling POST /sample_sets with a JSON mime type" do
    it "should create the samples when valid parameters are given" do
      sample_set = mock_model(SampleSet)
      SampleSet.should_receive(:new).with(
        {"naming_scheme_id" => "12",
        "sample_prep_kit_id" => "4",
        "reference_genome_id" => "7",
        "project_id" => "43",
        "alignment_start_position" => "1",
        "alignment_end_position" => "36",
        "desired_read_length" => "36",
        "eland_parameter_set_id" => "3",
        "budget_number" => "12345678",
        "submitted_by" => "bmarzolf",
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
        "submitted_by" => "bmarzolf",
        "samples" => [
          { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Key" => "YO 1" },
          { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 2" }
        ] }
    end
  end

end
