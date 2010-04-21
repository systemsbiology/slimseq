require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleMixturesController do
  include AuthenticatedSpecHelper

  def mock_sample_mixture(stubs={})
    @mock_sample_mixture ||= mock_model(SampleMixture, stubs)
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

  describe "responding to GET edit" do

    before(:each) do
      login_as_user
      mock_user_methods

      @sample_mixture = mock_sample_mixture
    end
    
    def do_get
      get :edit, :id => "37"
    end
    
    it "should expose the requested sample mixture as @sample_mixture" do
      SampleMixture.should_receive(:find).with("37").and_return(@sample_mixture)
      do_get
      assigns[:sample_mixture].should == @sample_mixture
    end
    
  end

  describe "responding to PUT udpate" do

    before(:each) do
      login_as_user
      mock_user_methods
    end
    
    def do_put
      put :update, :id => "37", :sample_mixture => { :these => 'params' }
    end

    describe "with valid params" do

      it "should update the requested sample mixture" do
        SampleMixture.should_receive(:find).with("37").and_return(mock_sample_mixture)
        mock_sample_mixture.should_receive(:update_attributes).with({'these' => 'params'})
        do_put
      end

      it "should expose the requested sample as @sample_mixture" do
        SampleMixture.stub!(:find).and_return(mock_sample_mixture(:update_attributes => true))
        do_put
        assigns[:sample_mixture].should equal(mock_sample_mixture)
      end

      it "should redirect to sample_mixtures/index" do
        SampleMixture.stub!(:find).and_return(mock_sample_mixture(:update_attributes => true))
        do_put
        response.should redirect_to(sample_mixtures_url)
      end

    end
    
    describe "with invalid params" do

      it "should expose the sample as @sample_mixture" do
        SampleMixture.stub!(:find).and_return(mock_sample_mixture(:update_attributes => false))
        do_put
        assigns[:sample_mixture].should equal(mock_sample_mixture)
      end

      it "should re-render the 'edit' template" do
        SampleMixture.stub!(:find).and_return(mock_sample_mixture(:update_attributes => false))
        do_put
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
    
    describe "with submitted sample mixtures" do
      
      it "should destroy the requested sample" do
        @sample_mixture = mock_sample_mixture
        @sample_mixture.should_receive(:status).and_return("submitted")
        SampleMixture.should_receive(:find).with("37").and_return(@sample_mixture)
        mock_sample_mixture.should_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect back" do
        @sample_mixture = mock_sample_mixture(:destroy => true)
        @sample_mixture.should_receive(:status).and_return("submitted")
        SampleMixture.stub!(:find).and_return(@sample_mixture)
        delete :destroy, :id => "1"
        response.should redirect_to("http://test.host/refering_url")
      end

    end

    describe "with clustered sample mixtures" do

      it "should not destroy the requested sample mixture" do
        @sample_mixture = mock_sample_mixture
        @sample_mixture.should_receive(:status).and_return("clustered")
        SampleMixture.should_receive(:find).with("37").and_return(@sample_mixture)
        mock_sample_mixture.should_not_receive(:destroy)
        delete :destroy, :id => "37"
      end

      it "should redirect back" do
        @sample_mixture = mock_sample_mixture(:destroy => true)
        @sample_mixture.should_receive(:status).and_return("clustered")
        SampleMixture.stub!(:find).and_return(@sample_mixture)
        delete :destroy, :id => "1"
        response.should redirect_to("http://test.host/refering_url")
      end

    end
    
  end

  describe "responding to bulk handler" do
    
    before(:each) do
      @sample_mixture1 = mock_model(Sample)
      @sample_mixture2 = mock_model(Sample)

      SampleMixture.should_receive(:find).once.and_return(@sample_mixture1, @sample_mixture2)
    end

    describe "deleting selected samples" do
        
      describe "with staff or admin privileges" do

        before(:each) do
          login_as_staff
          mock_user_methods
          
          # turn the current user into an admin
          @current_user.should_receive(:staff_or_admin?).any_number_of_times.and_return(true)
      
          @sample_mixture1.should_receive(:name_on_tube).and_return("s1")
          @sample_mixture2.should_receive(:name_on_tube).and_return("s2")
        end

        it "should allow bulk destroy of submitted samples" do
          @sample_mixture1.should_receive(:submitted?).and_return(true)
          @sample_mixture2.should_receive(:submitted?).and_return(true)
          
          @sample_mixture1.should_receive(:destroy).and_return(true)
          @sample_mixture2.should_receive(:destroy).and_return(true)
          
          post :bulk_handler, :selected_sample_mixtures => {'1' => '1',
                                                    '2' => '1'},
               :commit => "Delete Selected Samples"

          response.should redirect_to(samples_url)
        end

        it "should not allow bulk destroy of clustered, sequenced or completed samples" do
          @sample_mixture1.should_receive(:submitted?).and_return(false)
          @sample_mixture2.should_receive(:submitted?).and_return(false)
          
          @sample_mixture1.should_not_receive(:destroy)
          @sample_mixture1.should_not_receive(:destroy)
          
          post :bulk_handler, :selected_sample_mixtures => {'1' => '1',
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

        @sample_mixture1.should_not_receive(:destroy)
        @sample_mixture1.should_not_receive(:destroy)

        post :bulk_handler, :selected_sample_mixtures => {'1' => '1',
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
      
      post :bulk_handler, :selected_sample_mixtures => {'1' => '1',
                                                '2' => '1'},
           :commit => "Show Details"

      response.should render_template('details')
    end

  end
  
  describe "responding to GET browse" do
    
    before(:each) do
      login_as_user

      mock_samples = mock("Array of samples")
      Sample.should_receive(:accessible_to_user).and_return(mock_samples)

      @mock_tree = mock("Sample tree")
      Sample.should_receive(:browse_by).and_return(@mock_tree)
    end

    it "should expose a sample tree as @tree" do
      get :browse, :category1 => 'project', :category2 => 'submitter'
      assigns(:tree).should == @mock_tree
    end 

    it "should render the 'browse' view" do
      get :browse, :category1 => 'project', :category2 => 'submitter'
      response.should render_template('browse')
    end
  end

  describe "responding to GET search" do
  
    before(:each) do
      login_as_user

      @sample_mixture_1 = mock_model(SampleMixture)
      @sample_mixture_2 = mock_model(SampleMixture)
      @sample_mixture_3 = mock_model(SampleMixture)
      @accessible_samples = [@sample_mixture_1, @sample_mixture_3]
      @search_samples = [@sample_mixture_1, @sample_mixture_2]
      SampleMixture.stub!(:accessible_to_user).and_return(@accessible_samples)
      SampleMixture.stub!(:find_by_sanitized_conditions).and_return(@search_samples)
    end

    it "should get the samples accessible to the user" do
      SampleMixture.should_receive(:accessible_to_user).with(@current_user).
        and_return(@accessible_samples)
      get :search, :project_id => 5
    end

    it "should find samples with the given parameters" do
      SampleMixture.should_receive(:find_by_sanitized_conditions).with(
        "controller" => "sample_mixtures",
        "action" => "search",
        "project_id" => "5"
      ).and_return(@search_samples)
      get :search, :project_id => 5
    end

    it "should expose the searched samples that are accessible to the user" do
      get :search, :project_id => 5
      assigns[:sample_mixtures].should == [@sample_mixture_1]
    end

  end

  describe "responding to GET all" do
    
    before(:each) do
      login_as_user

      @mock_sample_mixtures = mock("Array of samples")
      SampleMixture.should_receive(:accessible_to_user).and_return(@mock_sample_mixtures)
    end

    it "should expose all accessible samples as @sample_mixtures" do
      get :all
      assigns[:sample_mixtures].should == @mock_sample_mixtures
    end 

    it "should render the 'list' view" do
      get :all
      response.should render_template('list')
    end

  end

end
