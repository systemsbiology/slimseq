require File.dirname(__FILE__) + '/../test_helper'

class NamingElementTest < Test::Unit::TestCase
  fixtures :naming_schemes, :naming_elements, :naming_terms, :samples,
           :sample_texts

  def test_destroy_warning_with_naming_terms
    expected_warning = "Destroying this naming element will also destroy:\n" + 
                       "2 naming term(s)\n" +
                       "0 sample text(s)\n" +
                       "Are you sure you want to destroy it?"
  
    element = NamingElement.find(2)   
    assert_equal expected_warning, element.destroy_warning
  end
  
  def test_destroy_warning_with_sample_texts
    expected_warning = "Destroying this naming element will also destroy:\n" + 
                       "0 naming term(s)\n" +
                       "1 sample text(s)\n" +
                       "Are you sure you want to destroy it?"
  
    element = NamingElement.find(5)   
    assert_equal expected_warning, element.destroy_warning
  end
end
