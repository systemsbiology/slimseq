require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/reference_genomes/edit.html.erb" do
  include ReferenceGenomesHelper
  
  before do
    @reference_genome = mock_model(ReferenceGenome)
    assigns[:reference_genome] = @reference_genome
  end

  it "should render edit form" do
    render "/reference_genomes/edit.html.erb"
    
    response.should have_tag("form[action=#{reference_genome_path(@reference_genome)}][method=post]") do
    end
  end
end


