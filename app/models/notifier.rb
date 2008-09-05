class Notifier < ActionMailer::Base

  def sample_submission_notification(samples)
    recipients SiteConfig.administrator_email
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] Samples recorded"
    body       :samples => samples
  end

  def bioanalyzer_notification(run, ran_by_email, email_recipients)
    recipients email_recipients
    cc         ran_by_email
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] New Bioanalyzer results"
    body       :run => run, :site_url => SiteConfig.site_url
  end
  
end
