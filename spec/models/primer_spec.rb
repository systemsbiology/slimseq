require 'spec_helper'

describe Primer do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :platform_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Primer.create!(@valid_attributes)
  end
end
