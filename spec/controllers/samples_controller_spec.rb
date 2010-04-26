require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SamplesController do
  include AuthenticatedSpecHelper

  def mock_sample(stubs={})
    @mock_sample ||= mock_model(Sample, stubs)
  end
  
  def mock_user_methods
    lab_groups = [mock_model(LabGroup), mock_model(LabGroup)]
    @current_user.stub!(:accessible_lab_groups).and_return(lab_groups)
    @current_user.stub!(:lab_groups).and_return(lab_groups)

    users = [mock_model(User), mock_model(User)]
    @current_user.stub!(:accessible_users).and_return(users)
  end

  before(:each) do
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
  
  describe "responding to GET index" do
    
    before(:each) do      
      login_as_user
      mock_user_methods

      @accessible_samples = [mock_model(Sample), mock_model(Sample)]
      @accessible_lab_group_ids = [1,2,3]
      @current_user.should_receive(:get_lab_group_ids).any_number_of_times.
        and_return(@accessible_lab_group_ids)
      SampleMixture.should_receive(:browsing_categories).and_return( mock("Browsing categories") )
      #User.should_receive(:all_by_id).and_return( mock("User hash") )
      controller.stub!(:paginate).and_return(["Samples Pages", @accessible_samples])
    end

    it "should expose all samples accessible by the user as @samples" do
      Sample.should_receive(:accessible_to_user).and_return(@accessible_samples)
      get :index
      assigns[:samples].should == @accessible_samples
    end

    describe "with mime type of xml" do
      it "should render all accessible samples as xml" do
        sample_1 = mock_model(Sample)
        sample_2 = mock_model(Sample)
        sample_1.should_receive(:summary_hash).and_return( {:n => 1} )
        sample_2.should_receive(:summary_hash).and_return( {:n => 2} )
        samples = [sample_1, sample_2]
        
        request.env["HTTP_ACCEPT"] = "application/xml"
        Sample.should_receive(:accessible_to_user).and_return(samples)
        get :index
        response.body.should ==
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  " +
          "<record>\n    <n type=\"integer\">1</n>\n  </record>\n  <record>\n    " +
          "<n type=\"integer\">2</n>\n  </record>\n</records>\n"
        
      end
      
    end

    describe "with mime type of json" do
  
      it "should render sample lane summaries as json" do
        sample_1 = mock_model(Sample)
        sample_2 = mock_model(Sample)
        sample_1.should_receive(:summary_hash).and_return( {:n => 1} )
        sample_2.should_receive(:summary_hash).and_return( {:n => 2} )
        samples = [sample_1, sample_2]
        
        request.env["HTTP_ACCEPT"] = "application/json"
        Sample.should_receive(:accessible_to_user).and_return(samples)
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end
    
    end
    
  end

  describe "responding to GET show" do

    before(:each) do
      login_as_user
      mock_user_methods

      @sample = mock_model(Sample)
      @sample.should_receive(:detail_hash).and_return( {:n => "1"} )
    end
    
    it "should expose the requested sample as @sample" do
      Sample.should_receive(:find).
        with("37", :include => { :sample_terms => { :naming_term => :naming_element} }).
        and_return(@sample)
      get :show, :id => "37"
      assigns[:sample].should equal(@sample)
    end
    
    describe "with mime type of xml" do

      it "should render the requested sample as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        Sample.should_receive(:find).
          with("37", :include => { :sample_terms => { :naming_term => :naming_element} }).
          and_return(@sample)
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
          "<hash>\n  <n>1</n>\n</hash>\n"
      end

    end

    describe "with mime type of json" do
  
      it "should render the flow cell lane detail as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        Sample.should_receive(:find).
          with("37", :include => { :sample_terms => { :naming_term => :naming_element} }).
          and_return(@sample)
        get :show, :id => 37
        response.body.should == "{\"n\":\"1\"}"
      end
    
    end
    
  end

end
