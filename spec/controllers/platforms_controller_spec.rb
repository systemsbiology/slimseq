require 'spec_helper'

describe PlatformsController do

  def mock_platform(stubs={})
    @mock_platform ||= mock_model(Platform, stubs)
  end

  describe "GET index" do
    it "assigns all platforms as @platforms" do
      Platform.stub(:find).with(:all).and_return([mock_platform])
      get :index
      assigns[:platforms].should == [mock_platform]
    end
  end

  describe "GET new" do
    it "assigns a new platform as @platform" do
      Platform.stub(:new).and_return(mock_platform)
      get :new
      assigns[:platform].should equal(mock_platform)
    end
  end

  describe "GET edit" do
    it "assigns the requested platform as @platform" do
      Platform.stub(:find).with("37").and_return(mock_platform)
      get :edit, :id => "37"
      assigns[:platform].should equal(mock_platform)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created platform as @platform" do
        Platform.stub(:new).with({'these' => 'params'}).and_return(mock_platform(:save => true))
        post :create, :platform => {:these => 'params'}
        assigns[:platform].should equal(mock_platform)
      end

      it "redirects to the created platform" do
        Platform.stub(:new).and_return(mock_platform(:save => true))
        post :create, :platform => {}
        response.should redirect_to(platforms_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved platform as @platform" do
        Platform.stub(:new).with({'these' => 'params'}).and_return(mock_platform(:save => false))
        post :create, :platform => {:these => 'params'}
        assigns[:platform].should equal(mock_platform)
      end

      it "re-renders the 'new' template" do
        Platform.stub(:new).and_return(mock_platform(:save => false))
        post :create, :platform => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested platform" do
        Platform.should_receive(:find).with("37").and_return(mock_platform)
        mock_platform.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :platform => {:these => 'params'}
      end

      it "assigns the requested platform as @platform" do
        Platform.stub(:find).and_return(mock_platform(:update_attributes => true))
        put :update, :id => "1"
        assigns[:platform].should equal(mock_platform)
      end

      it "redirects to the platform" do
        Platform.stub(:find).and_return(mock_platform(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(platforms_url)
      end
    end

    describe "with invalid params" do
      it "updates the requested platform" do
        Platform.should_receive(:find).with("37").and_return(mock_platform)
        mock_platform.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :platform => {:these => 'params'}
      end

      it "assigns the platform as @platform" do
        Platform.stub(:find).and_return(mock_platform(:update_attributes => false))
        put :update, :id => "1"
        assigns[:platform].should equal(mock_platform)
      end

      it "re-renders the 'edit' template" do
        Platform.stub(:find).and_return(mock_platform(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested platform" do
      Platform.should_receive(:find).with("37").and_return(mock_platform)
      mock_platform.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the platforms list" do
      Platform.stub(:find).and_return(mock_platform(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(platforms_url)
    end
  end

end
