require 'spec_helper'

describe MultiplexCode do
  before(:each) do
    @valid_attributes = {
      :sequence => "value for sequence",
      :multiplexing_scheme_id => 1,
      :name => "value for name"
    }
  end

  it "should create a new instance given valid attributes" do
    MultiplexCode.create!(@valid_attributes)
  end
end
