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
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
        "Subject Number" => "3283"
      }
      
      @naming_scheme.generate_sample_description(schemed_params).should == "wt_HT_024_A_3283"
    end
  end

  describe "generating a sample name from schemed parameters, with a hidden element" do
    it "should provide a string of the abbreviated terms and free text values" do
      schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => "-1",
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
        "Subject Number" => "3283"
      }
      
      @naming_scheme.generate_sample_description(schemed_params).should == "wt___A_3283"
    end
  end
  
  it "should provide the correct default visibilities" do
    naming_schemes(:yeast_scheme).default_visibilities.should == [true,true,false,true,true]
  end

  it "should provide the correct default texts" do
    naming_schemes(:yeast_scheme).default_texts.should == {'Subject Number' => ''}
  end

  it "should provide the correct visibilities from parameters" do
    schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
        "Subject Number" => "3283"
      }
    
    expected_visibilities = [true, true, true, true, true]
    
    naming_schemes(:yeast_scheme).visibilities_from_params(schemed_params).
      should == expected_visibilities
  end
  
  it "should provide the correct texts from parameters" do
    schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
        "Subject Number" => "3283"
      }
    
    expected_texts = {"Subject Number" => "3283"}
    
    naming_schemes(:yeast_scheme).texts_from_params(schemed_params).
      should == expected_texts
  end

  it "should provide the correct element selections from parameters" do
    schemed_params = {
        "Strain" => naming_terms(:wild_type).id, "Perturbation" => naming_terms(:heat).id,
        "Replicate" => naming_terms(:replicateA).id, "Perturbation Time" => naming_terms(:time024).id,
        "Subject Number" => "3283"
      }
    
    expected_selections = [naming_terms(:wild_type).id, naming_terms(:heat).id,
      naming_terms(:time024).id, naming_terms(:replicateA).id ]
    
    naming_schemes(:yeast_scheme).element_selections_from_params(schemed_params).
      should == expected_selections
  end
  
  it "should provide the correct visibilities from sample terms" do
    sample_terms = [sample_terms(:sample6_strain), sample_terms(:sample6_perturbation),
      sample_terms(:sample6_perturbation_time), sample_terms(:sample6_replicate) ]
    
    expected_visibilities = [true, true, true, true, true]
    
    naming_schemes(:yeast_scheme).visibilities_from_terms(sample_terms).
      should == expected_visibilities
  end
  
  it "should provide the correct texts from sample texts" do
    sample_texts = [sample_texts(:sample6_subject_number)]
    
    expected_texts = {"Subject Number" => "32234"}
    
    naming_schemes(:yeast_scheme).texts_from_terms(sample_texts).
      should == expected_texts
  end 

  it "should provide the correct element selections from sample terms" do
    sample_terms = [sample_terms(:sample6_strain), sample_terms(:sample6_perturbation),
      sample_terms(:sample6_perturbation_time), sample_terms(:sample6_replicate)]
    
    expected_selections = [naming_terms(:wild_type).id, naming_terms(:heat).id,
       naming_terms(:time024).id, naming_terms(:replicateB).id, -1]
    
    naming_schemes(:yeast_scheme).element_selections_from_terms(sample_terms).
      should == expected_selections
  end 
  
  it "should provide a hash of summary attributes" do
    naming_scheme = create_naming_scheme(:name => "Beast Scheme")
    
    naming_scheme.summary_hash.should == {
      :id => naming_scheme.id,
      :name => "Beast Scheme",
      :updated_at => naming_scheme.updated_at,
      :uri => "http://example.com/naming_schemes/#{naming_scheme.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    naming_scheme = create_naming_scheme(:name => "Beast Scheme")
    
    naming_element_1 = create_naming_element(
      :naming_scheme => naming_scheme,
      :name => "Age"
    )
    naming_element_2 = create_naming_element(
      :naming_scheme => naming_scheme,
      :name => "Subject Number",
      :free_text => true
    )
    
    create_naming_term(
      :naming_element => naming_element_1,
      :term => "Young"
    )
    create_naming_term(
      :naming_element => naming_element_1,
      :term => "Old"
    )

    expected_hash = {
      :id => naming_scheme.id,
      :name => "Beast Scheme",
      :updated_at => naming_scheme.reload.updated_at,
      :naming_elements => [
        {
          :name => "Age",
          :group_element => true,
          :optional => true,
          :free_text => false,
          :depends_on => nil,
          :naming_terms => ["Young", "Old"]
        },
        {
          :name => "Subject Number",
          :group_element => true,
          :optional => true,
          :free_text => true,
          :depends_on => nil,
          :naming_terms => []
        }
      ]
    }
    
    naming_scheme.detail_hash.should == expected_hash
  end
end
