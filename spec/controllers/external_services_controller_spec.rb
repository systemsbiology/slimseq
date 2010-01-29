require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExternalServicesController do

  def mock_external_service(stubs={})
    @mock_external_service ||= mock_model(ExternalService, stubs)
  end

  describe "GET index" do
    it "assigns all external_services as @external_services" do
      ExternalService.stub!(:find).with(:all).and_return([mock_external_service])
      get :index
      assigns[:external_services].should == [mock_external_service]
    end
  end

  describe "GET show" do
    it "assigns the requested external_service as @external_service" do
      ExternalService.stub!(:find).with("37").and_return(mock_external_service)
      get :show, :id => "37"
      assigns[:external_service].should equal(mock_external_service)
    end
  end

  describe "GET new" do
    it "assigns a new external_service as @external_service" do
      ExternalService.stub!(:new).and_return(mock_external_service)
      get :new
      assigns[:external_service].should equal(mock_external_service)
    end
  end

  describe "GET edit" do
    it "assigns the requested external_service as @external_service" do
      ExternalService.stub!(:find).with("37").and_return(mock_external_service)
      get :edit, :id => "37"
      assigns[:external_service].should equal(mock_external_service)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created external_service as @external_service" do
        ExternalService.stub!(:new).with({'these' => 'params'}).and_return(mock_external_service(:save => true))
        post :create, :external_service => {:these => 'params'}
        assigns[:external_service].should equal(mock_external_service)
      end

      it "redirects to the created external_service" do
        ExternalService.stub!(:new).and_return(mock_external_service(:save => true))
        post :create, :external_service => {}
        response.should redirect_to(external_service_url(mock_external_service))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved external_service as @external_service" do
        ExternalService.stub!(:new).with({'these' => 'params'}).and_return(mock_external_service(:save => false))
        post :create, :external_service => {:these => 'params'}
        assigns[:external_service].should equal(mock_external_service)
      end

      it "re-renders the 'new' template" do
        ExternalService.stub!(:new).and_return(mock_external_service(:save => false))
        post :create, :external_service => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested external_service" do
        ExternalService.should_receive(:find).with("37").and_return(mock_external_service)
        mock_external_service.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :external_service => {:these => 'params'}
      end

      it "assigns the requested external_service as @external_service" do
        ExternalService.stub!(:find).and_return(mock_external_service(:update_attributes => true))
        put :update, :id => "1"
        assigns[:external_service].should equal(mock_external_service)
      end

      it "redirects to the external_service" do
        ExternalService.stub!(:find).and_return(mock_external_service(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(external_service_url(mock_external_service))
      end
    end

    describe "with invalid params" do
      it "updates the requested external_service" do
        ExternalService.should_receive(:find).with("37").and_return(mock_external_service)
        mock_external_service.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :external_service => {:these => 'params'}
      end

      it "assigns the external_service as @external_service" do
        ExternalService.stub!(:find).and_return(mock_external_service(:update_attributes => false))
        put :update, :id => "1"
        assigns[:external_service].should equal(mock_external_service)
      end

      it "re-renders the 'edit' template" do
        ExternalService.stub!(:find).and_return(mock_external_service(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested external_service" do
      ExternalService.should_receive(:find).with("37").and_return(mock_external_service)
      mock_external_service.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the external_services list" do
      ExternalService.stub!(:find).and_return(mock_external_service(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(external_services_url)
    end
  end

end
