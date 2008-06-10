require File.dirname(__FILE__) + '/../test_helper'

class NamingTermTest < Test::Unit::TestCase
  fixtures :naming_schemes, :naming_elements, :naming_terms, :samples, :sample_terms

  def test_destroy_warning
    expected_warning = "Destroying this naming term will also destroy:\n" + 
                       "1 sample term(s)\n" +
                       "Are you sure you want to destroy it?"
  
    term = NamingTerm.find( naming_terms(:wild_type).id )   
    assert_equal expected_warning, term.destroy_warning
  end
end
