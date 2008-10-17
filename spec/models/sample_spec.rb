require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Sample do
  describe "getting naming element visibility" do
    fixtures :samples, :naming_schemes, :naming_elements, :naming_terms, :sample_terms,
             :sample_texts
    
    it "should return nil with no naming scheme" do
      samples(:sample5).naming_element_visibility.should == nil
    end
    
    it "should return the correct visibility settings with a naming scheme" do
      expected_visibilities = [true, true, true, true, true]
      samples(:sample6).naming_element_visibility.should == expected_visibilities
    end
  end

  describe "getting naming scheme text values" do
    fixtures :samples, :naming_schemes, :naming_elements, :naming_terms, :sample_terms,
             :sample_texts
    
    it "should return nil with no naming scheme" do
      samples(:sample5).text_values.should == nil
    end
    
    it "should return the correct text values with a naming scheme" do
      expected_texts = {"Subject Number" => "32234"}
      samples(:sample6).text_values.should == expected_texts
    end
  end

  describe "getting naming scheme element selections" do
    fixtures :samples, :naming_schemes, :naming_elements, :naming_terms, :sample_terms,
             :sample_texts
    
    it "should return nil with no naming scheme" do
      samples(:sample5).text_values.should == nil
    end
    
    it "should return the correct selections with a naming scheme" do
      expected_selections = [naming_terms(:wild_type).id, naming_terms(:heat).id,
                             naming_terms(:time024).id, naming_terms(:replicateB).id, -1 ]
      samples(:sample6).naming_element_selections.should == expected_selections
    end
  end
  
  describe "making sample terms from schemed parameters" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide an array of the sample terms" do
      @sample = Sample.new(:naming_scheme_id => naming_schemes(:yeast_scheme))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
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

  describe "making sample terms from schemed parameters, with a hidden dependent element" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide an array of the sample terms" do
      @sample = Sample.new(:naming_scheme_id => naming_schemes(:yeast_scheme))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => "-1",
        "Perturbation Time" => naming_terms(:time024).id,
        "Replicate" => naming_terms(:replicateA).id, "Subject Number" => "3283"
      }
      
      expected_terms = [
        @sample.sample_terms.build(:term_order => 1, :naming_term_id => naming_terms(:wild_type).id),
        @sample.sample_terms.build(:term_order => 2, :naming_term_id => naming_terms(:replicateA).id)
      ]

      @sample.terms_for(schemed_params).each do |observed_term|
        expected_term = expected_terms.shift
        observed_term.attributes.should == expected_term.attributes
      end
    end
  end
  
  describe "making sample texts from schemed parameters" do
    fixtures :naming_schemes, :naming_elements, :naming_terms
    
    it "should provide a hash of the sample texts" do
      @sample = Sample.new(:naming_scheme_id => naming_schemes(:yeast_scheme))
      
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA), "Perturbation Time" => naming_terms(:time024),
        "Subject Number" => "3283"
      }
      
      expected_texts = [
        SampleText.new(:sample_id => @sample.id,
                       :naming_element_id => naming_elements(:subject_number).id,
                       :text => "3283"),
      ]

      @sample.texts_for(schemed_params).each do |observed_text|
        expected_text = expected_texts.shift
        observed_text.attributes.should == expected_text.attributes
      end
    end
  end
  
  describe "setting the schemed name attribute for a sample" do
    fixtures :all
    
    def do_set
      @sample = samples(:sample6)
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
        "Subject Number" => "3283"
      }
      @sample.schemed_name = schemed_params
    end
    
    it "should create the appropriate sample terms" do
      do_set

      expected_attribute_sets = [
        { :term_order => 1, :naming_term_id => naming_terms(:wild_type).id },
        { :term_order => 2, :naming_term_id => naming_terms(:heat).id },
        { :term_order => 3, :naming_term_id => naming_terms(:time024).id },
        { :term_order => 4, :naming_term_id => naming_terms(:replicateA).id }
      ]

      @sample.sample_terms.find(:all, :order => "term_order ASC").each do |term|
        attribute_set = expected_attribute_sets.shift
        attribute_set.each do |key, value|
          term[key].should == value
        end
      end
    end
    
    it "should create the appropriate sample texts" do       
      do_set

      attribute_set = { :naming_element_id => naming_elements(:subject_number).id, :text => "3283" }

      text = @sample.sample_texts.find(:all)[0]
      attribute_set.each do |key, value|
        text[key].should == value
      end
    end
  end
end