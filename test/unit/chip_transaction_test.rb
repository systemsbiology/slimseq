require File.dirname(__FILE__) + '/../test_helper'

class ChipTransactionTest < Test::Unit::TestCase
  fixtures :chip_types, :lab_groups, :chip_transactions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ChipTransaction, chip_transactions(:acquired)
  end
end
