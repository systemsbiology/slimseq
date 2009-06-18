require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ElandParameterSetsController do

  def mock_eland_parameter_set(stubs={})
    @mock_eland_parameter_set ||= mock_model(ElandParameterSet, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all eland_parameter_sets as @eland_parameter_sets" do
      ElandParameterSet.should_receive(:find).with(:all).and_return([mock_eland_parameter_set])
      get :index
      assigns[:eland_parameter_sets].should == [mock_eland_parameter_set]
    end

    describe "with mime type of xml" do
  
      it "should render all eland_parameter_sets as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        ElandParameterSet.should_receive(:find).with(:all).and_return(eland_parameter_sets = mock("Array of ElandParameterSets"))
        eland_parameter_sets.should_receive(:to_xml).and_return("generated XML")
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested eland_parameter_set as @eland_parameter_set" do
      ElandParameterSet.should_receive(:find).with("37").and_return(mock_eland_parameter_set)
      get :show, :id => "37"
      assigns[:eland_parameter_set].should equal(mock_eland_parameter_set)
    end
    
    describe "with mime type of xml" do

      it "should render the requested eland_parameter_set as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        ElandParameterSet.should_receive(:find).with("37").and_return(mock_eland_parameter_set)
        mock_eland_parameter_set.should_receive(:to_xml).and_return("generated XML")
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new eland_parameter_set as @eland_parameter_set" do
      ElandParameterSet.should_receive(:new).and_return(mock_eland_parameter_set)
      get :new
      assigns[:eland_parameter_set].should equal(mock_eland_parameter_set)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested eland_parameter_set as @eland_parameter_set" do
      ElandParameterSet.should_receive(:find).with("37").and_return(mock_eland_parameter_set)
      get :edit, :id => "37"
      assigns[:eland_parameter_set].should equal(mock_eland_parameter_set)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created eland_parameter_set as @eland_parameter_set" do
        ElandParameterSet.should_receive(:new).with({'these' => 'params'}).and_return(mock_eland_parameter_set(:save => true))
        post :create, :eland_parameter_set => {:these => 'params'}
        assigns(:eland_parameter_set).should equal(mock_eland_parameter_set)
      end

      it "should redirect to the created eland_parameter_set" do
        ElandParameterSet.stub!(:new).and_return(mock_eland_parameter_set(:save => true))
        post :create, :eland_parameter_set => {}
        response.should redirect_to(eland_parameter_sets_url)
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved eland_parameter_set as @eland_parameter_set" do
        ElandParameterSet.stub!(:new).with({'these' => 'params'}).and_return(mock_eland_parameter_set(:save => false))
        post :create, :eland_parameter_set => {:these => 'params'}
        assigns(:eland_parameter_set).should equal(mock_eland_parameter_set)
      end

      it "should re-render the 'new' template" do
        ElandParameterSet.stub!(:new).and_return(mock_eland_parameter_set(:save => false))
        post :create, :eland_parameter_set => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested eland_parameter_set" do
        ElandParameterSet.should_receive(:find).with("37").and_return(mock_eland_parameter_set)
        mock_eland_parameter_set.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :eland_parameter_set => {:these => 'params'}
      end

      it "should expose the requested eland_parameter_set as @eland_parameter_set" do
        ElandParameterSet.stub!(:find).and_return(mock_eland_parameter_set(:update_attributes => true))
        put :update, :id => "1"
        assigns(:eland_parameter_set).should equal(mock_eland_parameter_set)
      end

      it "should redirect to the eland_parameter_set" do
        ElandParameterSet.stub!(:find).and_return(mock_eland_parameter_set(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(eland_parameter_sets_url)
      end

    end
    
    describe "with invalid params" do

      it "should update the requested eland_parameter_set" do
        ElandParameterSet.should_receive(:find).with("37").and_return(mock_eland_parameter_set)
        mock_eland_parameter_set.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :eland_parameter_set => {:these => 'params'}
      end

      it "should expose the eland_parameter_set as @eland_parameter_set" do
        ElandParameterSet.stub!(:find).and_return(mock_eland_parameter_set(:update_attributes => false))
        put :update, :id => "1"
        assigns(:eland_parameter_set).should equal(mock_eland_parameter_set)
      end

      it "should re-render the 'edit' template" do
        ElandParameterSet.stub!(:find).and_return(mock_eland_parameter_set(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested eland_parameter_set" do
      ElandParameterSet.should_receive(:find).with("37").and_return(mock_eland_parameter_set)
      mock_eland_parameter_set.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the eland_parameter_sets list" do
      ElandParameterSet.stub!(:find).and_return(mock_eland_parameter_set(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(eland_parameter_sets_url)
    end

  end

end
