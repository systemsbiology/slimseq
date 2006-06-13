require File.dirname(__FILE__) + '/../test_helper'

class HybridizationTest < Test::Unit::TestCase
  fixtures :hybridizations

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Hybridization, hybridizations(:first)
  end
end
