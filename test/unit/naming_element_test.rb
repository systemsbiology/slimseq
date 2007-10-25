require File.dirname(__FILE__) + '/../test_helper'

class NamingElementTest < Test::Unit::TestCase
  fixtures :naming_schemes, :naming_elements, :naming_terms, :samples

  def test_destroy_warning
    expected_warning = "Destroying this naming element will also destroy:\n" + 
                       "2 naming term(s)\n" +
                       "Are you sure you want to destroy it?"
  
    element = NamingElement.find(2)   
    assert_equal expected_warning, element.destroy_warning
  end
end
