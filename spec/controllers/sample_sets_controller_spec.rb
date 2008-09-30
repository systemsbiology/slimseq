require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe SampleSetsController do
  before(:each) do
    login_as_user
    
    lab_groups = [mock_model(LabGroup), mock_model(LabGroup)]
    @current_user.stub!(:accessible_lab_groups).and_return(lab_groups)
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
        @sample_set.stub!(:valid?).and_return(true)
        @sample_set.stub!(:submission_date).and_return('2008-02-01')
        @sample_set.stub!(:naming_scheme_id).and_return(1)
        @sample_set.stub!(:sample_prep_kit_id).and_return(1)
        @sample_set.stub!(:budget_number).and_return("1234")
        Sample.stub!(:new).and_return( mock_model(Sample) )
      end

      def do_get
        get :new, :step => "2", :sample_set => { :number_of_samples => 2 }
      end

      it "should be successful" do
        do_get
        response.should be_success
      end

      it "should render table partial" do
        do_get
        response.should render_partial('table')
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
  end

#  describe "handling GET /sample_sets/1/edit" do
#
#    before(:each) do
#      @sample_set = mock_model(SampleSet)
#      SampleSet.stub!(:find).and_return(@sample_set)
#    end
#  
#    def do_get
#      get :edit, :id => "1"
#    end
#
#    it "should be successful" do
#      do_get
#      response.should be_success
#    end
#  
#    it "should render edit template" do
#      do_get
#      response.should render_template('edit')
#    end
#  
#    it "should find the sample_set requested" do
#      SampleSet.should_receive(:find).and_return(@sample_set)
#      do_get
#    end
#  
#    it "should assign the found SampleSet for the view" do
#      do_get
#      assigns[:sample_set].should equal(@sample_set)
#    end
#  end
end