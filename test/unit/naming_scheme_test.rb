require File.dirname(__FILE__) + '/../test_helper'

class NamingSchemeTest < Test::Unit::TestCase
  fixtures :samples, :hybridizations, :naming_schemes

  def test_destroy_warning
    expected_warning = "Destroying this naming scheme will also destroy:\n" + 
                       "1 sample(s)\n" +
                       "5 naming element(s)\n" +
                       "Are you sure you want to destroy it?"
  
    scheme = NamingScheme.find( naming_schemes(:yeast_scheme).id )   
    assert_equal expected_warning, scheme.destroy_warning
  end
end
