require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/reference_genomes/index.html.erb" do
  include ReferenceGenomesHelper
  
  before(:each) do
    reference_genome_98 = mock_model(ReferenceGenome)
    reference_genome_99 = mock_model(ReferenceGenome)

    assigns[:reference_genomes] = [reference_genome_98, reference_genome_99]
  end

  it "should render list of reference_genomes" do
    render "/reference_genomes/index.html.erb"
  end
end

