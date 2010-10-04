require 'spec_helper'

describe PipelineResultFile do
  before(:each) do
    @valid_attributes = {
      :file_path => "value for file_path"
    }
  end

  it "should create a new instance given valid attributes" do
    PipelineResultFile.create!(@valid_attributes)
  end
end
