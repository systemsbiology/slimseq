require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe SampleSetsController do
  before(:each) do
    login_as_user
    
    lab_groups = [mock_model(LabGroup), mock_model(LabGroup)]
    @current_user.stub!(:accessible_lab_groups).and_return(lab_groups)
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
          @sample_set.stub!(:valid?).and_return(true)
          @sample_set.stub!(:submission_date).and_return('2008-02-01')
          @sample_set.stub!(:sample_prep_kit_id).and_return(1)
          @sample_set.stub!(:budget_number).and_return("1234")
          @sample_set.stub!(:reference_genome_id).and_return(1)
          @sample_set.stub!(:desired_read_length).and_return(18)
          @sample_set.stub!(:alignment_start_position).and_return(1)
          @sample_set.stub!(:alignment_end_position).and_return(17)
          @sample_set.stub!(:insert_size).and_return(150)
          @sample = mock_model(Sample)
          @sample.stub!(:populate_default_visibilities_and_texts)
          Sample.stub!(:new).and_return( @sample )
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
end