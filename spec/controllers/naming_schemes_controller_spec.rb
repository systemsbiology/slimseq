require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe NamingSchemesController do
  before(:each) do
    login_as_staff
  end

  def mock_naming_scheme(stubs={})
    @mock_naming_scheme ||= mock_model(NamingScheme, stubs)
  end
  
  describe "responding to GET index" do

    before(:each) do
      @naming_scheme_1 = mock_model(NamingScheme)
      @naming_scheme_2 = mock_model(NamingScheme)
      @naming_schemes = [@naming_scheme_1, @naming_scheme_2]
      
      NamingScheme.should_receive(:find).with(:all, {:order=>"name ASC"}).
        and_return(@naming_schemes)
    end
    
    it "should expose all naming_schemes as @naming_schemes" do
      get :index
      assigns[:naming_schemes].should == @naming_schemes
    end

    describe "with mime type of xml" do
  
      it "should render all naming_schemes as xml" do
        @naming_scheme_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @naming_scheme_2.should_receive(:summary_hash).and_return( {:n => 2} )

        request.env["HTTP_ACCEPT"] = "application/xml"
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
          "<records type=\"array\">\n  <record>\n    <n type=\"integer\">1</n>\n  </record>" +
          "\n  <record>\n    <n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end
    
    end

    describe "with mime type of json" do
  
      it "should render flow cell summaries as json" do       
        @naming_scheme_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @naming_scheme_2.should_receive(:summary_hash).and_return( {:n => 2} )

        request.env["HTTP_ACCEPT"] = "application/json"
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end
    
    end
    
  end

  describe "responding to GET show" do

    before(:each) do
      @naming_scheme = mock_model(NamingScheme)
      @naming_scheme.should_receive(:detail_hash).and_return( {:n => 1} )
      NamingScheme.should_receive(:find).with("37").and_return(@naming_scheme)
    end
    
    it "should expose the requested naming_scheme as @naming_scheme" do
      get :show, :id => "37"
      assigns[:naming_scheme].should equal(@naming_scheme)
    end
    
    describe "with mime type of xml" do

      it "should render the requested naming_scheme as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
          "<hash>\n  <n type=\"integer\">1</n>\n</hash>\n"
      end

    end

    describe "with mime type of json" do
  
      it "should render the flow cell detail as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        get :show, :id => 37
        response.body.should == "{\"n\":1}"
      end
    
    end
    
  end

  describe "responding to GET new" do
    before(:each) do
      @naming_scheme = mock_naming_scheme
      NamingScheme.should_receive(:new).and_return(@naming_scheme)
    end
  
    it "should expose a new naming_scheme as @naming_scheme" do
      get :new
      assigns[:naming_scheme].should equal(@naming_scheme)
    end

  end

  describe "responding to GET rename" do
  
    it "should expose the requested naming_scheme as @naming_scheme" do
      NamingScheme.should_receive(:find).with("37").and_return(mock_naming_scheme)
      get :rename, :id => "37"
      assigns[:naming_scheme].should equal(mock_naming_scheme)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created naming_scheme as @naming_scheme" do
        NamingScheme.should_receive(:new).with({'these' => 'params'}).and_return(mock_naming_scheme(:save => true))
        post :create, :naming_scheme => {:these => 'params'}
        assigns(:naming_scheme).should equal(mock_naming_scheme)
      end

      it "should redirect to the created naming_scheme" do
        NamingScheme.stub!(:new).and_return(mock_naming_scheme(:save => true))
        post :create, :naming_scheme => {}
        response.should redirect_to(naming_schemes_url)
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved naming_scheme as @naming_scheme" do
        NamingScheme.stub!(:new).with({'these' => 'params'}).and_return(mock_naming_scheme(:save => false))
        post :create, :naming_scheme => {:these => 'params'}
        assigns(:naming_scheme).should equal(mock_naming_scheme)
      end

      it "should re-render the 'new' template" do
        NamingScheme.stub!(:new).and_return(mock_naming_scheme(:save => false))
        post :create, :naming_scheme => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested naming_scheme" do
        NamingScheme.should_receive(:find).with("37").and_return(mock_naming_scheme)
        mock_naming_scheme.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :naming_scheme => {:these => 'params'}
      end

      it "should expose the requested naming_scheme as @naming_scheme" do
        NamingScheme.stub!(:find).and_return(mock_naming_scheme(:update_attributes => true))
        put :update, :id => "1"
        assigns(:naming_scheme).should equal(mock_naming_scheme)
      end

      it "should redirect to the naming_scheme" do
        NamingScheme.stub!(:find).and_return(mock_naming_scheme(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(naming_schemes_url)
      end

    end
    
    describe "with invalid params" do

      it "should update the requested naming_scheme" do
        NamingScheme.should_receive(:find).with("37").and_return(mock_naming_scheme)
        mock_naming_scheme.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :naming_scheme => {:these => 'params'}
      end

      it "should expose the naming_scheme as @naming_scheme" do
        NamingScheme.stub!(:find).and_return(mock_naming_scheme(:update_attributes => false))
        put :update, :id => "1"
        assigns(:naming_scheme).should equal(mock_naming_scheme)
      end

      it "should re-render the 'rename' template" do
        NamingScheme.stub!(:find).and_return(mock_naming_scheme(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('rename')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested naming_scheme" do
      NamingScheme.should_receive(:find).with("37").and_return(mock_naming_scheme)
      mock_naming_scheme.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the naming_schemes list" do
      NamingScheme.stub!(:find).and_return(mock_naming_scheme(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(naming_schemes_url)
    end

  end

end
