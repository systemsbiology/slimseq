require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RegistrationsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
  end
  
  describe "GET 'new'" do
    before(:each) do
      @user = mock_model(User)
      User.stub!(:new).and_return(@user)
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
  
    it "should create an new user" do
      User.should_receive(:new).and_return(@user)
      do_get
    end
  
    it "should not save the new user" do
      @user.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new user for the view" do
      do_get
      assigns[:user].should equal(@user)
    end
  end

  describe "GET 'create'" do
    before(:each) do
      @user = mock_model(User, :to_param => "1")
      User.stub!(:new).and_return(@user)
    end
    
    describe "with successful save" do
  
      def do_post
        @user.should_receive(:save).and_return(true)
        post :create, :user => {}
      end
  
      it "should create a new user" do
        User.should_receive(:new).with({}).and_return(@user)
        do_post
      end

      it "should redirect to the user index" do
        do_post
        response.should redirect_to(users_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @user.should_receive(:save).and_return(false)
        post :create, :user => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end
end
