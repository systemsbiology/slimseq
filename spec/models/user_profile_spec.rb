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

  it "should provide a list of user profiles that have new sample notification turned on" do
    user_profile_1 = create_user_profile(:new_sample_notification => true)
    user_profile_2 = create_user_profile(:new_sample_notification => true)
    user_profile_3 = create_user_profile(:new_sample_notification => false)
    user_profile_4 = create_user_profile(:new_sample_notification => true, :role => "staff")
        
    user_1 = mock_model(User, :user_profile => user_profile_1)
    user_2 = mock_model(User, :user_profile => user_profile_2)
    user_3 = mock_model(User, :user_profile => user_profile_3)
    user_4 = mock_model(User, :user_profile => user_profile_4)


    lab_group = mock_model(LabGroup, :users => [user_2,user_3])

    UserProfile.notify_of_new_samples(lab_group).should == [user_profile_2, user_profile_4]
  end
end
