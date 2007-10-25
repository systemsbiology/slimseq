require File.dirname(__FILE__) + '/../test_helper'

class NamingSchemeTest < Test::Unit::TestCase
  fixtures :chip_types, :samples, :hybridizations, :inventory_checks, :chip_transactions

  def test_destroy_warning
    expected_warning = "Destroying this naming scheme will also destroy:\n" + 
                       "1 sample(s)\n" +
                       "4 naming element(s)\n" +
                       "Are you sure you want to destroy it?"
  
    scheme = NamingScheme.find(1)   
    assert_equal expected_warning, scheme.destroy_warning
  end
end
