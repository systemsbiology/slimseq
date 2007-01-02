require File.dirname(__FILE__) + '/../test_helper'

class QualityTraceTest < Test::Unit::TestCase
  fixtures :quality_traces

  def test_destroy_with_samples_associated
    QualityTrace.find(6).destroy
    
    assert_raise(ActiveRecord::RecordNotFound) {
      QualityTrace.find(6)
    }
    
    assert_nil Sample.find(1).starting_quality_trace_id
  end
end
