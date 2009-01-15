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
          :depends_on => "",
          :naming_terms => ["Young", "Old"]
        },
        {
          :name => "Subject Number",
          :group_element => true,
          :optional => true,
          :free_text => true,
          :depends_on => "",
          :naming_terms => []
        }
      ]
    }
    
    naming_scheme.detail_hash.should == expected_hash
  end

  it "should create a CSV file describing a naming scheme" do
    naming_schemes(:yeast_scheme).to_csv

    csv_file_name = "#{RAILS_ROOT}/tmp/csv/#{SiteConfig.site_name}_naming_scheme_" +
      "Yeast Scheme-#{Date.today.to_s}.csv"
    csv = CSV.open(csv_file_name, 'r')

    expected_contents = [
      ["Naming Element","Strain"],
      ["Order","1"],
      ["Group Element","Yes"],
      ["Optional","No"],
      ["Free Text","No"],
      ["Depends On",""],
      ["Include in Sample Description","Yes"],
      ["Naming Terms"],
      ["Term","Abbreviated Term","Order"],
      ["wild-type","wt","0"],
      ["mutant","mut","1"],
      [""],
      ["Naming Element","Perturbation"],
      ["Order","2"],
      ["Group Element","Yes"],
      ["Optional","No"],
      ["Free Text","No"],
      ["Depends On",""],
      ["Include in Sample Description","Yes"],
      ["Naming Terms"],
      ["Term","Abbreviated Term","Order"],
      ["heat","HT","0"],
      ["heavy metals","HM","1"],
      [""],
      ["Naming Element","Perturbation Time"],
      ["Order","3"],
      ["Group Element","Yes"],
      ["Optional","Yes"],
      ["Free Text","No"],
      ["Depends On","Perturbation"],
      ["Include in Sample Description","Yes"],
      ["Naming Terms"],
      ["Term","Abbreviated Term","Order"],
      ["000","000","0"],
      ["024","024","1"],
      [""],
      ["Naming Element","Replicate"],
      ["Order","4"],
      ["Group Element","No"],
      ["Optional","No"],
      ["Free Text","No"],
      ["Depends On",""],
      ["Include in Sample Description","No"],
      ["Naming Terms"],
      ["Term","Abbreviated Term","Order"],
      ["A","A","0"],
      ["B","B","1"],
      [""],
      ["Naming Element","Subject Number"],
      ["Order","5"],
      ["Group Element","No"],
      ["Optional","No"],
      ["Free Text","Yes"],
      ["Depends On",""],
      ["Include in Sample Description","Yes"],
      [""],
    ]

    expected_contents.each do |row|
      csv.shift.should eql(row)
    end
  end

  it "should create a new naming scheme based on a CSV of the format created by to_csv" do
    csv_file_name = "#{RAILS_ROOT}/spec/fixtures/toad_naming_scheme.csv"

    scheme = NamingScheme.from_csv("Toad Scheme", csv_file_name)

    elements = scheme.naming_elements.find(:all, :order => "element_order ASC")

    elements[0].name.should == "Food"
    elements[0].element_order.should == 1
    elements[0].group_element.should == true
    elements[0].optional.should == false
    elements[0].free_text.should == false
    elements[0].dependent_element_id.should == nil
    elements[0].include_in_sample_description.should == true
    terms = elements[0].naming_terms.find(:all, :order => "term_order ASC")
    terms[0].term.should == "None"
    terms[0].abbreviated_term.should == "None"
    terms[0].term_order.should == 1
    terms[1].term.should == "Fruit Flies"
    terms[1].abbreviated_term.should == "FF"
    terms[1].term_order.should == 2
    terms[2].term.should == "Horse Flies"
    terms[2].abbreviated_term.should == "HF"
    terms[2].term_order.should == 3

    elements[1].name.should == "Food Amount"
    elements[1].element_order.should == 2
    elements[1].group_element.should == true
    elements[1].optional.should == false
    elements[1].free_text.should == false
    elements[1].dependent_element_id.should == elements[0].id
    elements[1].include_in_sample_description.should == true
    terms = elements[1].naming_terms.find(:all, :order => "term_order ASC")
    terms[0].term.should == "Small"
    terms[0].abbreviated_term.should == "S"
    terms[0].term_order.should == 1
    terms[1].term.should == "Large"
    terms[1].abbreviated_term.should == "L"
    terms[1].term_order.should == 2

    elements[2].name.should == "Name"
    elements[2].element_order.should == 3
    elements[2].group_element.should == false
    elements[2].optional.should == false
    elements[2].free_text.should == true
    elements[2].dependent_element_id.should == nil
    elements[2].include_in_sample_description.should == true
  end
  

end
