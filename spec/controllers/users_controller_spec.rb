require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe UsersController do
  before(:each) do
    login_as_staff
  end

  def mock_user(stubs={})
    @mock_user ||= mock_model(User, stubs)
  end

  describe "responding to GET index" do

    before(:each) do
      @user_1 = mock_model(User)
      @user_2 = mock_model(User)
      @users = [@user_1, @user_2]

      User.should_receive(:find).with(:all, :order => "lastname ASC").and_return(@users)
    end

    it "should expose all users as @users" do
      get :index
      assigns[:users].should == @users
    end

    describe "with mime type of xml" do

      it "should render all users as xml" do
        @user_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @user_2.should_receive(:summary_hash).and_return( {:n => 2} )
        request.env["HTTP_ACCEPT"] = "application/xml"
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  " +
          "<record>\n    <n type=\"integer\">1</n>\n  </record>\n  <record>\n    " +
          "<n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end

    end

    describe "with mime type of json" do

      it "should render flow cell summaries as json" do
        @user_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @user_2.should_receive(:summary_hash).and_return( {:n => 2} )
        request.env["HTTP_ACCEPT"] = "application/json"
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end

    end

  end

  describe "responding to GET show" do

    describe "with mime type of xml" do

      it "should render the requested user as xml" do
        user = mock_model(User)
        user.should_receive(:detail_hash).and_return( {:n => 1} )

        request.env["HTTP_ACCEPT"] = "application/xml"
        User.should_receive(:find).with("37").and_return(user)
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  "+
          "<n type=\"integer\">1</n>\n</hash>\n"
      end

    end

    describe "with mime type of json" do

      it "should render the flow cell detail as json" do
        user = mock_model(User)
        user.should_receive(:detail_hash).and_return( {:n => 1} )

        request.env["HTTP_ACCEPT"] = "application/json"
        User.should_receive(:find).with("37").and_return(user)
        get :show, :id => 37
        response.body.should == "{\"n\":1}"
      end

    end

  end
  
end