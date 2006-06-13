require File.dirname(__FILE__) + '/../test_helper'

class ChargeSetTest < Test::Unit::TestCase
  fixtures :charge_sets

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ChargeSet, charge_sets(:first)
  end
end
