require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReportsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end

  describe "GET 'billing'" do
    it "should be successful" do
      FlowCellLane.should_receive(:find).and_return( mock("Paged samples") )
      User.should_receive(:all_by_id).and_return( mock("User hash") )
      get 'billing'
      response.should be_success
    end
  end

end
