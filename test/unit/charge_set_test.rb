require File.dirname(__FILE__) + '/../test_helper'

class ChargeSetTest < Test::Unit::TestCase
  fixtures :charge_sets, :charges

  def test_get_totals
    expected_totals = Hash.new(0)
    expected_totals['chips'] = 1
    expected_totals['chip_cost'] = 400
    expected_totals['labeling_cost'] = 280
    expected_totals['hybridization_cost'] = 100
    expected_totals['qc_cost'] = 25
    expected_totals['other_cost'] = 0
    expected_totals['total_cost'] = 805

    set = ChargeSet.find(1)
    assert_equal expected_totals, set.get_totals
  end

  def test_destroy_warning
    expected_warning = "Destroying this charge set will also destroy:\n" + 
                       "2 charge(s)\n" +
                       "Are you sure you want to destroy it?"
  
    set = ChargeSet.find(1)   
    assert_equal expected_warning, set.destroy_warning
  end
end
