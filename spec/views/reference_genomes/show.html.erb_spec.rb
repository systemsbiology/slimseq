require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/reference_genomes/show.html.erb" do
  include ReferenceGenomesHelper
  
  before(:each) do
    @reference_genome = mock_model(ReferenceGenome)

    assigns[:reference_genome] = @reference_genome
  end

  it "should render attributes in <p>" do
    render "/reference_genomes/show.html.erb"
  end
end

