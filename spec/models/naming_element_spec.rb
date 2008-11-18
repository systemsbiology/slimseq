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
end
