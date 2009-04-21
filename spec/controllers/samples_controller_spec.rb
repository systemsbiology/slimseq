require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SamplesController do
  include AuthenticatedSpecHelper

  fixtures :all

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
      #User.should_receive(:all_by_id).and_return( mock("User hash") )
      controller.stub!(:paginate).and_return(["Samples Pages", @accessible_samples])
    end

    it "should expose all samples accessible by the user as @samples" do
      Sample.should_receive(:find).twice.and_return(@accessible_samples)
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
        Sample.should_receive(:find).twice.and_return(samples)
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
        Sample.should_receive(:find).twice.and_return(samples)
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

  describe "responding to GET edit" do

    before(:each) do
      login_as_user
      mock_user_methods

      @sample = mock_sample
      @sample.stub!(:naming_scheme).and_return(nil)     
    end
    
    def do_get
      get :edit, :id => "37"
    end
    
    it "should expose the requested sample as @sample" do
      Sample.should_receive(:find).with("37").and_return(@sample)
      do_get
      assigns[:sample].should == @sample
    end
    
    it "should expose the requested sample in an array with size 1 as @samples" do
      Sample.should_receive(:find).with("37").and_return(@sample)
      do_get
      assigns[:samples].should == [@sample]
    end

    it "should not populate @naming_elements if the sample has no naming scheme" do
      Sample.should_receive(:find).with("37").and_return(@sample)
      @sample.stub!(:naming_scheme).and_return(nil)
      do_get
      assigns[:naming_elements].should == nil
    end

    it "should populate @naming_elements if the sample has a naming scheme" do
      Sample.should_receive(:find).with("37").and_return(@sample)
      @naming_scheme = mock_model(NamingScheme)
      @naming_elements = [mock_model(NamingElement), mock_model(NamingElement)]
      @naming_scheme.should_receive(:ordered_naming_elements).and_return(@naming_elements)
      @sample.stub!(:naming_scheme).and_return(@naming_scheme)
      do_get
      assigns[:naming_elements].should == @naming_elements
    end    

  end

  describe "responding to PUT udpate" do

    before(:each) do
      login_as_user
      mock_user_methods
    end
    
    describe "with valid params" do

      it "should update the requested sample" do
        Sample.should_receive(:find).with("37").and_return(mock_sample)
        mock_sample.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :sample => { "0" => {:these => 'params'} }
      end

      it "should expose the requested sample as @sample" do
        Sample.stub!(:find).and_return(mock_sample(:update_attributes => true))
        put :update, :id => "37", :sample => { "0" => {:these => 'params'} }
        assigns(:sample).should equal(mock_sample)
      end

      it "should redirect to the sample" do
        Sample.stub!(:find).and_return(mock_sample(:update_attributes => true))
        put :update, :id => "37", :sample => { "0" => {:these => 'params'} }
        response.should redirect_to(samples_url)
      end

    end
    
    describe "with invalid params" do

      it "should update the requested sample" do
        Sample.should_receive(:find).with("37").and_return(mock_sample)
        mock_sample.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :sample => { "0" => {:these => 'params'} }
      end

      it "should expose the sample as @sample" do
        Sample.stub!(:find).and_return(mock_sample(:update_attributes => false))
        put :update, :id => "37", :sample => { "0" => {:these => 'params'} }
        assigns(:sample).should equal(mock_sample)
      end

      it "should re-render the 'edit' template" do
        Sample.stub!(:find).and_return(mock_sample(:update_attributes => false))
        put :update, :id => "37", :sample => { "0" => {:these => 'params'} }
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    before(:each) do
      login_as_user
      mock_user_methods

      request.env["HTTP_REFERER"] = "/refering_url"
      @current_user.stub!(:staff_or_admin?).and_return(false)
    end
    
    describe "with submitted samples" do
      
      it "should destroy the requested sample" do
        @sample = mock_sample
        @sample.should_receive(:status).and_return("submitted")
        Sample.should_receive(:find).with("37").and_return(@sample)
        mock_sample.should_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect back" do
        @sample = mock_sample(:destroy => true)
        @sample.should_receive(:status).and_return("submitted")
        Sample.stub!(:find).and_return(@sample)
        delete :destroy, :id => "1"
        response.should redirect_to("http://test.host/refering_url")
      end

    end

    describe "with clustered samples" do

      it "should not destroy the requested sample" do
        @sample = mock_sample
        @sample.should_receive(:status).and_return("clustered")
        Sample.should_receive(:find).with("37").and_return(@sample)
        mock_sample.should_not_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect back" do
        @sample = mock_sample(:destroy => true)
        @sample.should_receive(:status).and_return("clustered")
        Sample.stub!(:find).and_return(@sample)
        delete :destroy, :id => "1"
        response.should redirect_to("http://test.host/refering_url")
      end

    end
    
  end

  describe "responding to bulk handler" do
    
    before(:each) do
      @sample1 = mock_model(Sample)
      @sample2 = mock_model(Sample)

      Sample.should_receive(:find).once.and_return(@sample1, @sample2)
    end

    describe "deleting selected samples" do
        
      describe "with staff or admin privileges" do

        before(:each) do
          login_as_staff
          mock_user_methods
          
          # turn the current user into an admin
          @current_user.should_receive(:staff_or_admin?).any_number_of_times.and_return(true)
      
          @sample1.should_receive(:name_on_tube).and_return("s1")
          @sample2.should_receive(:name_on_tube).and_return("s2")
        end

        it "should allow bulk destroy of submitted samples" do
          @sample1.should_receive(:submitted?).and_return(true)
          @sample2.should_receive(:submitted?).and_return(true)
          
          @sample1.should_receive(:destroy).and_return(true)
          @sample2.should_receive(:destroy).and_return(true)
          
          post :bulk_handler, :selected_samples => {'1' => '1',
                                                    '2' => '1'},
               :commit => "Delete Selected Samples"

          response.should redirect_to(samples_url)
        end

        it "should not allow bulk destroy of clustered, sequenced or completed samples" do
          @sample1.should_receive(:submitted?).and_return(false)
          @sample2.should_receive(:submitted?).and_return(false)
          
          @sample1.should_not_receive(:destroy)
          @sample1.should_not_receive(:destroy)
          
          post :bulk_handler, :selected_samples => {'1' => '1',
                                                    '2' => '1'},
               :commit => "Delete Selected Samples"

          response.should redirect_to(samples_url)
        end

      end

      it "should not allow bulk destroy for non staff or admin users" do
        login_as_user
        mock_user_methods

        # turn the current user into an admin
        @current_user.should_receive(:staff_or_admin?).any_number_of_times.and_return(false)

        @sample1.should_not_receive(:destroy)
        @sample1.should_not_receive(:destroy)

        post :bulk_handler, :selected_samples => {'1' => '1',
                                                  '2' => '1'},
             :commit => "Delete Selected Samples"

        response.should redirect_to(samples_url)
      end
    
    end

    it "should show details for selected samples" do
      login_as_user
      mock_user_methods

      # turn the current user into an admin
      @current_user.should_receive(:staff_or_admin?).any_number_of_times.and_return(true)
      
      post :bulk_handler, :selected_samples => {'1' => '1',
                                                '2' => '1'},
           :commit => "Show Details"

      response.should render_template('details')
    end

  end
  
end
