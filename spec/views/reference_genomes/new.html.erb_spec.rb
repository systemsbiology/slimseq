require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/reference_genomes/new.html.erb" do
  include ReferenceGenomesHelper
  
  before(:each) do
    @reference_genome = mock_model(ReferenceGenome)
    @reference_genome.stub!(:new_record?).and_return(true)
    assigns[:reference_genome] = @reference_genome
  end

  it "should render new form" do
    render "/reference_genomes/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", reference_genomes_path) do
    end
  end
end


