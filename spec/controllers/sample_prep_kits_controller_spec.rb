require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SamplePrepKitsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
  end
  
  def mock_sample_prep_kit(stubs={})
    @mock_sample_prep_kit ||= mock_model(SamplePrepKit, stubs)
  end
  
  describe "responding to GET index" do

    before(:each) do
      @sample_prep_kit_1 = mock_model(SamplePrepKit)
      @sample_prep_kit_2 = mock_model(SamplePrepKit)
      @sample_prep_kits = [@sample_prep_kit_1, @sample_prep_kit_2]
      SamplePrepKit.should_receive(:find).with(:all).and_return(@sample_prep_kits)
    end
    
    it "should expose all sample_prep_kits as @sample_prep_kits" do
      get :index
      assigns[:sample_prep_kits].should == @sample_prep_kits
    end

    describe "with mime type of xml" do
  
      it "should render all sample_prep_kits as xml" do
        @sample_prep_kit_1.should_receive(:detail_hash).and_return({:n => 1})
        @sample_prep_kit_2.should_receive(:detail_hash).and_return({:n => 2})
        request.env["HTTP_ACCEPT"] = "application/xml"
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=" +
          "\"array\">\n  <record>\n    <n type=\"integer\">1</n>\n  </record>\n  <record>\n" +
          "    <n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end
    
    end
    
    describe "with mime type of json" do
  
      it "should render all sample_prep_kits as json" do
        @sample_prep_kit_1.should_receive(:detail_hash).and_return({:n => 1})
        @sample_prep_kit_2.should_receive(:detail_hash).and_return({:n => 2})
        request.env["HTTP_ACCEPT"] = "application/json"
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end
    
    end    

  end

  describe "responding to GET show" do
    
    before(:each) do
      @sample_prep_kit = mock_model(SamplePrepKit)
      @sample_prep_kit.should_receive(:detail_hash).and_return({:n => 1})
      SamplePrepKit.should_receive(:find).with("37").and_return(@sample_prep_kit)
    end

    describe "with mime type of xml" do

      it "should render the requested sample_prep_kit as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  " +
          "<n type=\"integer\">1</n>\n</hash>\n"
      end

    end
    
    describe "with mime type of json" do

      it "should render the requested sample_prep_kit as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        get :show, :id => "37"
        response.body.should == "{\"n\":1}"
      end

    end    
    
  end

  describe "responding to GET new" do
  
    it "should expose a new sample_prep_kit as @sample_prep_kit" do
      SamplePrepKit.should_receive(:new).and_return(mock_sample_prep_kit)
      get :new
      assigns[:sample_prep_kit].should equal(mock_sample_prep_kit)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested sample_prep_kit as @sample_prep_kit" do
      SamplePrepKit.should_receive(:find).with("37").and_return(mock_sample_prep_kit)
      get :edit, :id => "37"
      assigns[:sample_prep_kit].should equal(mock_sample_prep_kit)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created sample_prep_kit as @sample_prep_kit" do
        SamplePrepKit.should_receive(:new).with({'these' => 'params'}).and_return(mock_sample_prep_kit(:save => true))
        post :create, :sample_prep_kit => {:these => 'params'}
        assigns(:sample_prep_kit).should equal(mock_sample_prep_kit)
      end

      it "should redirect to the created sample_prep_kit" do
        SamplePrepKit.stub!(:new).and_return(mock_sample_prep_kit(:save => true))
        post :create, :sample_prep_kit => {}
        response.should redirect_to(sample_prep_kits_url)
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved sample_prep_kit as @sample_prep_kit" do
        SamplePrepKit.stub!(:new).with({'these' => 'params'}).and_return(mock_sample_prep_kit(:save => false))
        post :create, :sample_prep_kit => {:these => 'params'}
        assigns(:sample_prep_kit).should equal(mock_sample_prep_kit)
      end

      it "should re-render the 'new' template" do
        SamplePrepKit.stub!(:new).and_return(mock_sample_prep_kit(:save => false))
        post :create, :sample_prep_kit => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested sample_prep_kit" do
        SamplePrepKit.should_receive(:find).with("37").and_return(mock_sample_prep_kit)
        mock_sample_prep_kit.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :sample_prep_kit => {:these => 'params'}
      end

      it "should expose the requested sample_prep_kit as @sample_prep_kit" do
        SamplePrepKit.stub!(:find).and_return(mock_sample_prep_kit(:update_attributes => true))
        put :update, :id => "1"
        assigns(:sample_prep_kit).should equal(mock_sample_prep_kit)
      end

      it "should redirect to the sample_prep_kit" do
        SamplePrepKit.stub!(:find).and_return(mock_sample_prep_kit(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(sample_prep_kits_url)
      end

    end
    
    describe "with invalid params" do

      it "should update the requested sample_prep_kit" do
        SamplePrepKit.should_receive(:find).with("37").and_return(mock_sample_prep_kit)
        mock_sample_prep_kit.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :sample_prep_kit => {:these => 'params'}
      end

      it "should expose the sample_prep_kit as @sample_prep_kit" do
        SamplePrepKit.stub!(:find).and_return(mock_sample_prep_kit(:update_attributes => false))
        put :update, :id => "1"
        assigns(:sample_prep_kit).should equal(mock_sample_prep_kit)
      end

      it "should re-render the 'edit' template" do
        SamplePrepKit.stub!(:find).and_return(mock_sample_prep_kit(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested sample_prep_kit" do
      SamplePrepKit.should_receive(:find).with("37").and_return(mock_sample_prep_kit)
      mock_sample_prep_kit.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the sample_prep_kits list" do
      SamplePrepKit.stub!(:find).and_return(mock_sample_prep_kit(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(sample_prep_kits_url)
    end

  end

end
