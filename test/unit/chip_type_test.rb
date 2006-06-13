require File.dirname(__FILE__) + '/../test_helper'

class ChipTypeTest < Test::Unit::TestCase
  fixtures :chip_types

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ChipType, chip_types(:mouse)
  end
end
