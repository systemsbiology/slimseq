require 'rubygems'
require 'scrubyt'
require 'test/unit'

class PatternTest < Test::Unit::TestCase

  def test_select_indices
    some_pattern =  Scrubyt::Pattern.new('some_pattern')
    some_pattern.select_indices(1..3)
    assert_equal(some_pattern.result_indexer.indices_to_extract, [1,2,3])
    some_pattern.select_indices([1])
    assert_equal(some_pattern.result_indexer.indices_to_extract, [1])
    some_pattern.select_indices([1,2,3])
    assert_equal(some_pattern.result_indexer.indices_to_extract, [1,2,3])
    some_pattern.select_indices(:first)
    assert_equal(some_pattern.result_indexer.indices_to_extract, [:first])
    some_pattern.select_indices([:first, :last])
    assert_equal(some_pattern.result_indexer.indices_to_extract, [:first,:last])
    some_pattern.select_indices([:first, [5,6]])
    assert_equal(some_pattern.result_indexer.indices_to_extract, [:first,5,6])
    some_pattern.select_indices([:first, 1..2])    
    assert_equal(some_pattern.result_indexer.indices_to_extract, [:first,1,2])
    some_pattern.select_indices([4..5, :first, [5,6]])
    assert_equal(some_pattern.result_indexer.indices_to_extract, [:first,4,5,6]) 
  end

end