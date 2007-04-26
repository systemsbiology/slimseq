require File.dirname(__FILE__) + '/../test_helper'

class ChargePeriodTest < Test::Unit::TestCase
  fixtures :charge_periods, :charge_sets

  def test_destroy_warning
    expected_warning = "Destroying this charge period will also destroy:\n" + 
                       "3 charge set(s)\n" +
                       "Are you sure you want to destroy it?"
  
    period = ChargePeriod.find(1)   
    assert_equal expected_warning, period.destroy_warning
  end
end
