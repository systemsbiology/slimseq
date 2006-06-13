require File.dirname(__FILE__) + '/../test_helper'

class InventoryCheckTest < Test::Unit::TestCase
  fixtures :inventory_checks

  # Replace this with your real tests.
  def test_truth
    assert_kind_of InventoryCheck, inventory_checks(:first)
  end
end
