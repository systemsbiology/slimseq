require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabGroupProfile do
  before(:each) do
    @valid_attributes = {
      :file_folder => "value for file_folder"
    }
  end

  it "should create a new instance given valid attributes" do
    LabGroupProfile.create!(@valid_attributes)
  end
end
