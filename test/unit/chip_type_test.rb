require File.dirname(__FILE__) + '/../test_helper'

class ChipTypeTest < Test::Unit::TestCase
  fixtures :chip_types, :samples, :hybridizations, :inventory_checks, :chip_transactions

  def test_destroy_warning
    expected_warning = "Destroying this chip type will also destroy:\n" + 
                       "6 sample(s)\n" +
                       "2 inventory check(s)\n" +
                       "2 chip transaction(s)\n" +
                       "Are you sure you want to destroy it?"
  
    type = ChipType.find( chip_types(:alligator) )   
    assert_equal expected_warning, type.destroy_warning
  end
end
