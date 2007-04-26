require File.dirname(__FILE__) + '/../test_helper'

class LabGroupTest < Test::Unit::TestCase
  fixtures :lab_groups, :samples, :charge_sets, :hybridizations, :inventory_checks,
           :chip_transactions, :projects

  def test_destroy_warning
    expected_warning = "Destroying this lab group will also destroy:\n" + 
                       "3 charge set(s)\n" +
                       "2 project(s)\n" +
                       "2 inventory check(s)\n" +
                       "2 chip transaction(s)\n" +
                       "Are you sure you want to destroy it?"

    group = LabGroup.find(1)   
    assert_equal expected_warning, group.destroy_warning
  end
end
