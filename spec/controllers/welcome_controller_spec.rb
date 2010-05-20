require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WelcomeController do
  include AuthenticatedSpecHelper

  describe "handling GET /welcome" do
    
    it "should redirect staff or admin to 'staff' action" do
      login_as_staff
      get :index
      response.should redirect_to(:action => 'staff')
    end

    it "should redirect customers to 'home' action" do
      login_as_user
      get :index
      response.should redirect_to(:action => 'home')
    end

  end

  describe "handling GET /welcome/home" do
    
    context "as a staff user" do

      it "should redirect to 'staff'" do
        login_as_staff
        get :home
        response.should redirect_to(:action => 'staff')
      end

    end

    context "as a customer user" do
      
      before(:each) do
        login_as_user
      end

      it "should not look up any samples if the user is part of no lab groups" do
        @current_user.should_receive(:get_lab_group_ids).and_return([])
        get :home
      end

      it "should find incomplete and complete samples if the user belongs to lab groups" do
        @current_user.should_receive(:get_lab_group_ids).and_return([42,47])
        sample_mixtures = mock("Incomplete Sample Mixtures")
        complete_sample_mixtures = mock("Complete Sample Mixtures")

        SampleMixture.should_receive(:find).with(
          :all, 
          :include => 'project',
          :conditions => [ "status != ? AND projects.lab_group_id IN (?) AND control = ?",
            'completed', [42,47], false ],
          :order => "sample_mixtures.id ASC"
        ).and_return(sample_mixtures)

        SampleMixture.should_receive(:find).with(
          :all, 
          :include => 'project',
          :conditions => [ "status = ? AND projects.lab_group_id IN (?) AND control = ?",
            'completed', [42,47], false ],
          :order => "sample_mixtures.submission_date DESC",
          :limit => 10
        ).and_return(complete_sample_mixtures)

        User.should_receive(:all_by_id).and_return( mock("Users by id Hash") )

        get :home
      end
    end

  end
end
