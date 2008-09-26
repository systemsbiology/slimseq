require File.dirname(__FILE__) + '/../test_helper'

class LabGroupTest < Test::Unit::TestCase
  fixtures :lab_groups, :samples, :charge_sets, :hybridizations, :projects

  def test_destroy_warning
    expected_warning = "Destroying this lab group will also destroy:\n" + 
                       "3 charge set(s)\n" +
                       "2 project(s)\n" +
                       "Are you sure you want to destroy it?"

    group = LabGroup.find( lab_groups(:gorilla_group).id )   
    assert_equal expected_warning, group.destroy_warning
  end
end
