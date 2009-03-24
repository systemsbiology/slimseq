class Notifier < ActionMailer::Base

  def sample_submission_notification(samples)
    recipients UserProfile.notify_of_new_samples.collect{|x| x.user.email}.join(",")
    from       %("SLIMseq" <slimseq@#{`hostname`.strip}>)
    subject    "[SLIMseq] Samples recorded"
    body       :samples => samples
  end

  def sequencing_run_notification(sequencing_run)
    recipients UserProfile.notify_of_new_sequencing_runs.collect{|x| x.user.email}.join(",")
    from       %("SLIMseq" <slimseq@#{`hostname`.strip}>)
    subject    "[SLIMseq] New sequencing run created"
    body       :sequencing_run => sequencing_run
  end
  
end
