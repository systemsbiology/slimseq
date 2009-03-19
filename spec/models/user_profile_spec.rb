require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserProfile do
  before(:each) do
    @valid_attributes = {
      :role => "value for role",
      :new_sample_notification => false,
      :new_sequencing_run_notification => false
    }
  end

  it "should create a new instance given valid attributes" do
    UserProfile.create!(@valid_attributes)
  end
end
