require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReferenceGenome do
  before(:each) do
    @reference_genome = ReferenceGenome.new
  end

  it "should be valid" do
    @reference_genome.should be_valid
  end
end
