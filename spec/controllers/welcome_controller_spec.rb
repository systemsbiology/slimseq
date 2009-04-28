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
        samples = mock("Incomplete Samples")
        complete_samples = mock("Complete Samples")

        Sample.should_receive(:find).with(
          :all, 
          :include => 'project',
          :conditions => [ "status != ? AND projects.lab_group_id IN (?) AND control = ?",
            'completed', [42,47], false ],
          :order => "samples.id ASC"
        ).and_return(samples)

        Sample.should_receive(:find).with(
          :all, 
          :include => 'project',
          :conditions => [ "status = ? AND projects.lab_group_id IN (?) AND control = ?",
            'completed', [42,47], false ],
          :order => "samples.submission_date DESC",
          :limit => 10
        ).and_return(complete_samples)

        User.should_receive(:all_by_id).and_return( mock("Users by id Hash") )

        get :home
      end
    end

  end
end
