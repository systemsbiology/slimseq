require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Instrument do
  it "should provide the instrument name with the version" do
    instrument = create_instrument(:name => "Megasequencer",
      :instrument_version => "G8")
    instrument.name_with_version.should == "Megasequencer (G8)"
  end
end
