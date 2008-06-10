require File.dirname(__FILE__) + '/../test_helper'

class QualityTraceTest < Test::Unit::TestCase
  fixtures :quality_traces, :samples

  def test_destroy_with_samples_associated
    QualityTrace.find( quality_traces(:quality_trace_00006).id ).destroy
    
    assert_raise(ActiveRecord::RecordNotFound) {
      QualityTrace.find( quality_traces(:quality_trace_00006).id )
    }
    
    assert_nil Sample.find( samples(:sample1) ).starting_quality_trace_id
  end
end
