require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserProfile do

  # fix for the first user who logs in automatically being an admin
  before(:all) do
    create_user_profile
  end

  describe "determining if user has staff or admin privileges" do
    it "should be true when the user's role is 'staff'" do
      user_profile = create_user_profile(:role => "staff")
      user_profile.staff_or_admin?.should be_true
    end

    it "should be true when the user's role is 'admin'" do
      user_profile = create_user_profile(:role => "admin")
      user_profile.staff_or_admin?.should be_true
    end

    it "should be false when the user's role is 'customer'" do
      user_profile = create_user_profile(:role => "customer")
      user_profile.staff_or_admin?.should be_false
    end
  end

  describe "determining if the user has admin privileges" do
    it "should be false when the user's role is 'staff'" do
      user_profile = create_user_profile(:role => "staff")
      user_profile.admin?.should be_false
    end

    it "should be true when the user's role is 'admin'" do
      user_profile = create_user_profile(:role => "admin")
      user_profile.admin?.should be_true
    end

    it "should be false when the user's role is 'customer'" do
      user_profile = create_user_profile(:role => "customer")
      user_profile.admin?.should be_false
    end
  end

  it "should provide a detail hash of attributes" do
    user_profile = UserProfile.create

    user_profile.detail_hash.should == {}
  end
end
