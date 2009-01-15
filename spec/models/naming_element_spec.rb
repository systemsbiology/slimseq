require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NamingElement do
  it "should sort the naming terms" do
    naming_element = create_naming_element

    term_1 = create_naming_term(:naming_element => naming_element, :term => "DEF")
    term_2 = create_naming_term(:naming_element => naming_element, :term => "ABC")
    
    naming_element.sort_terms
    
    term_1.reload.term_order.should == 2
    term_2.reload.term_order.should == 1
  end

  it "should provide the name of the element it depends upon, if it has one" do
    vaccination = create_naming_element(:name => "Vaccination")
    vaccination_date = create_naming_element(
      :name => "Vaccination Date",
      :dependent_element_id => vaccination.id
    )

    vaccination_date.depends_upon_name.should == "Vaccination"
  end

  it "should provide an empty String if the element depends on no other element" do
    age = create_naming_element(
      :name => "Age",
      :dependent_element_id => nil
    )

    age.depends_upon_name.should == ""
  end
end
