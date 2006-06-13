require File.dirname(__FILE__) + '/../test_helper'

class AddHybsTest < Test::Unit::TestCase
  fixtures :add_hybs

  # Replace this with your real tests.
  def test_truth
    assert_kind_of AddHybs, add_hybs(:first)
  end
end
