require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NamingScheme do
  fixtures :all
  
  before(:each) do
    @naming_scheme = naming_schemes(:yeast_scheme)
  end

  it "destroy warning" do
    expected_warning = "Destroying this naming scheme will also destroy:\n" + 
                       "1 sample(s)\n" +
                       "5 naming element(s)\n" +
                       "Are you sure you want to destroy it?"
  
    scheme = NamingScheme.find( naming_schemes(:yeast_scheme).id )   
    scheme.destroy_warning.should == expected_warning
  end

  describe "generating a sample name from schemed parameters" do
    it "should provide a string of the abbreviated terms and free text values" do
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA), "Perturbation Time" => naming_terms(:time024),
        "Subject Number" => "3283"
      }
      
      @naming_scheme.generate_sample_name(schemed_params).should == "wt_HT_024_A_3283"
    end
  end
end
