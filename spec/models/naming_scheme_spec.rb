require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NamingScheme do
  fixtures :all
  
  before(:each) do
    @naming_scheme = naming_schemes(:yeast_scheme)
  end

  describe "generating a sample name from schemed data" do
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
