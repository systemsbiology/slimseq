require File.dirname(__FILE__) + '/../test_helper'

class ChipTransactionTest < Test::Unit::TestCase
  fixtures :chip_types, :lab_groups, :chip_transactions

  def test_find_all_in_lab_group_chip_type
    transactions = ChipTransaction.find_all_in_lab_group_chip_type(
      lab_groups(:gorilla_group).id,
      chip_types(:alligator)
    )
    
    assert_equal 2, transactions.size
  end
end
