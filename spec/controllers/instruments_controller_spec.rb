require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InstrumentsController do

  def mock_instrument(stubs={})
    @mock_instrument ||= mock_model(Instrument, stubs)
  end
  
  describe "responding to GET index" do

    before(:each) do
      @instrument_1 = mock_model(Instrument)
      @instrument_2 = mock_model(Instrument)
      @instruments = [@instrument_1, @instrument_2]
      Instrument.should_receive(:find).with(:all).and_return(@instruments)
    end
    
    it "should expose all instruments as @instruments" do
      get :index
      assigns[:instruments].should == @instruments
    end

    describe "with mime type of xml" do
  
      it "should render all instruments as xml" do
        @instrument_1.should_receive(:detail_hash).and_return({:n => 1})
        @instrument_2.should_receive(:detail_hash).and_return({:n => 2})
        request.env["HTTP_ACCEPT"] = "application/xml"
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=" +
          "\"array\">\n  <record>\n    <n type=\"integer\">1</n>\n  </record>\n  <record>\n" +
          "    <n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end
    
    end
    
    describe "with mime type of json" do
  
      it "should render all instruments as json" do
        @instrument_1.should_receive(:detail_hash).and_return({:n => 1})
        @instrument_2.should_receive(:detail_hash).and_return({:n => 2})
        request.env["HTTP_ACCEPT"] = "application/json"
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end
    
    end  
    
  end

  describe "responding to GET show" do

    before(:each) do
      @instrument = mock_model(Instrument)
      @instrument.should_receive(:detail_hash).and_return({:n => 1})
      Instrument.should_receive(:find).with("37").and_return(@instrument)
    end
    
    it "should expose the requested instrument as @instrument" do
      get :show, :id => "37"
      assigns[:instrument].should equal(@instrument)
    end
    
    describe "with mime type of xml" do

      it "should render the requested instrument as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  " +
          "<n type=\"integer\">1</n>\n</hash>\n"
      end

    end
    
    describe "with mime type of json" do

      it "should render the requested instrument as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        get :show, :id => "37"
        response.body.should == "{\"n\":1}"
      end

    end   
    
  end

  describe "responding to GET new" do
  
    it "should expose a new instrument as @instrument" do
      Instrument.should_receive(:new).and_return(mock_instrument)
      get :new
      assigns[:instrument].should equal(mock_instrument)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested instrument as @instrument" do
      Instrument.should_receive(:find).with("37").and_return(mock_instrument)
      get :edit, :id => "37"
      assigns[:instrument].should equal(mock_instrument)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created instrument as @instrument" do
        Instrument.should_receive(:new).with({'these' => 'params'}).and_return(mock_instrument(:save => true))
        post :create, :instrument => {:these => 'params'}
        assigns(:instrument).should equal(mock_instrument)
      end

      it "should redirect to the created instrument" do
        Instrument.stub!(:new).and_return(mock_instrument(:save => true))
        post :create, :instrument => {}
        response.should redirect_to(instruments_url)
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved instrument as @instrument" do
        Instrument.stub!(:new).with({'these' => 'params'}).and_return(mock_instrument(:save => false))
        post :create, :instrument => {:these => 'params'}
        assigns(:instrument).should equal(mock_instrument)
      end

      it "should re-render the 'new' template" do
        Instrument.stub!(:new).and_return(mock_instrument(:save => false))
        post :create, :instrument => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested instrument" do
        Instrument.should_receive(:find).with("37").and_return(mock_instrument)
        mock_instrument.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :instrument => {:these => 'params'}
      end

      it "should expose the requested instrument as @instrument" do
        Instrument.stub!(:find).and_return(mock_instrument(:update_attributes => true))
        put :update, :id => "1"
        assigns(:instrument).should equal(mock_instrument)
      end

      it "should redirect to the instrument" do
        Instrument.stub!(:find).and_return(mock_instrument(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(instruments_url)
      end

    end
    
    describe "with invalid params" do

      it "should update the requested instrument" do
        Instrument.should_receive(:find).with("37").and_return(mock_instrument)
        mock_instrument.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :instrument => {:these => 'params'}
      end

      it "should expose the instrument as @instrument" do
        Instrument.stub!(:find).and_return(mock_instrument(:update_attributes => false))
        put :update, :id => "1"
        assigns(:instrument).should equal(mock_instrument)
      end

      it "should re-render the 'edit' template" do
        Instrument.stub!(:find).and_return(mock_instrument(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested instrument" do
      Instrument.should_receive(:find).with("37").and_return(mock_instrument)
      mock_instrument.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the instruments list" do
      Instrument.stub!(:find).and_return(mock_instrument(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(instruments_url)
    end

  end

end
