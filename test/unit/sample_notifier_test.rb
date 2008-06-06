require File.dirname(__FILE__) + '/../test_helper'

class SampleNotifierTest < ActionMailer::TestCase
  tests SampleNotifier
  fixtures :samples, :site_config

  def setup
    ActionMailer::Base.deliveries = []
  end

  def test_submission_notification
    @new_samples = [ samples(:sample1), samples(:sample2) ]
    SampleNotifier.deliver_submission_notification(@new_samples)
    assert !ActionMailer::Base.deliveries.empty?

    sent = ActionMailer::Base.deliveries.first
    assert_equal [ site_config(:first).administrator_email ], sent.to
    assert_equal "SLIMarray: samples recorded", sent.subject
    assert sent.body =~ /^New samples have just been submitted/
    assert sent.body =~ /Young/
    assert sent.body =~ /Old/i
  end
  
end
