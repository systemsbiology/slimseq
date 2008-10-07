require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Sample do
#  describe "making a new sample" do
#    
#  end

  describe "making sample terms from schemed parameters" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide an array of the sample terms" do
      @sample = Sample.new(:naming_scheme_id => naming_schemes(:yeast_scheme))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA), "Perturbation Time" => naming_terms(:time024),
        "Subject Number" => "3283"
      }
      
      expected_terms = [
        @sample.sample_terms.build(:term_order => 1, :naming_term_id => naming_terms(:wild_type).id),
        @sample.sample_terms.build(:term_order => 2, :naming_term_id => naming_terms(:heat).id),
        @sample.sample_terms.build(:term_order => 3, :naming_term_id => naming_terms(:time024).id),
        @sample.sample_terms.build(:term_order => 4, :naming_term_id => naming_terms(:replicateA).id)
      ]

      @sample.terms_for(schemed_params).each do |observed_term|
        expected_term = expected_terms.shift
        observed_term.attributes.should == expected_term.attributes
      end
    end
  end

  describe "making sample texts from schemed parameters" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide an array of the sample terms" do
      @sample = Sample.new(:naming_scheme_id => naming_schemes(:yeast_scheme))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA), "Perturbation Time" => naming_terms(:time024),
        "Subject Number" => "3283"
      }
      
      expected_texts = [
        @sample.sample_texts.build(:naming_element_id => naming_elements(:subject_number).id,
                                   :text => "3283"),
      ]

      @sample.texts_for(schemed_params).each do |observed_text|
        expected_text = expected_texts.shift
        observed_text.attributes.should == expected_text.attributes
      end
    end
  end
end