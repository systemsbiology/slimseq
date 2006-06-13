require File.dirname(__FILE__) + '/../test_helper'

class ChargePeriodTest < Test::Unit::TestCase
  fixtures :charge_periods

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ChargePeriod, charge_periods(:first)
  end
end
