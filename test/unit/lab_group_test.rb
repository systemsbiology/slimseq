require File.dirname(__FILE__) + '/../test_helper'

class LabGroupTest < Test::Unit::TestCase
  fixtures :lab_groups

  def setup
    @lab_group = LabGroup.find(1)
  end
  
  def test_create
    assert_kind_of LabGroup, @lab_group
    assert_equal lab_groups(:bs_group).id, @lab_group.id
    assert_equal lab_groups(:bs_group).name, @lab_group.name
  end
  
  def test_update
    assert_equal lab_groups(:bs_group).name, @lab_group.name
    @lab_group.name = "Great Group"
    assert @lab_group.save, @lab_group.errors.full_messages.join("; ")
    @lab_group.reload
    assert_equal "Great Group", @lab_group.name
  end

# can't destroy since there are dependent records in chip_transactions
#  def test_destroy
#    @lab_group.destroy
#    assert_raise(ActiveRecord::RecordNotFound) { LabGroup.find(@lab_group.id) }
#  end

  def test_validate
    # try updating with a name that is too long
    assert_equal lab_groups(:bs_group).name, @lab_group.name
    @lab_group.name = "Exceptionally Long Name for a Lab Group"
    assert !@lab_group.save
    assert_equal 1, @lab_group.errors.count
    assert_equal "is too long (max is 20 characters)", @lab_group.errors.on(:name)
    
    # try creating a new record with an existing name
    @new_group = LabGroup.new(:name => "BS Lab Group")
    assert !@new_group.save
    assert_equal 1, @new_group.errors.count
    assert_equal "has already been taken", @new_group.errors.on(:name)
  end

end
