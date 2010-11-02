require 'spec_helper'

describe Platform do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :samples_per_flow_cell => "value for samples_per_flow_cell",
      :loading_location_name => "value for loading_location_name",
      :uses_gerald => false,
      :requires_concentrations => false
    }
  end

  it "should create a new instance given valid attributes" do
    Platform.create!(@valid_attributes)
  end
end
