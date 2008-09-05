require File.dirname(__FILE__) + '/../test_helper'

class NotifierTest < ActionMailer::TestCase
  tests Notifier
  fixtures :samples, :bioanalyzer_runs, :site_config

  def setup
    ActionMailer::Base.deliveries = []
  end

  def test_sample_submission_notification
    @new_samples = [ samples(:sample1), samples(:sample2) ]
    Notifier.deliver_sample_submission_notification(@new_samples)
    assert !ActionMailer::Base.deliveries.empty?

    sent = ActionMailer::Base.deliveries.first
    assert_equal [ site_config(:first).administrator_email ], sent.to
    assert_equal "[SLIMarray] Samples recorded", sent.subject
    assert sent.body =~ /^New samples have just been submitted/
    assert sent.body =~ /Young/
    assert sent.body =~ /Old/i
  end
  
  def test_bioanalyzer_notification
    run = bioanalyzer_runs(:bioanalyzer_run_00001)
    ran_by_email = 'facility@example.com'
    email_recipients = ['user1@example.com', 'user2@example.com']
    Notifier.deliver_bioanalyzer_notification(run, ran_by_email,
                                              email_recipients)
    assert !ActionMailer::Base.deliveries.empty?

    sent = ActionMailer::Base.deliveries.first
    assert_equal ['user1@example.com', 'user2@example.com'], sent.to
    assert_equal ['facility@example.com'], sent.cc
    assert_equal "[SLIMarray] New Bioanalyzer results", sent.subject
    assert sent.body =~ /^You have new Bioanalyzer results/
    assert sent.body =~ /bioanalyzer_runs\/show\//
  end
end
