class ExternalService < ActiveRecord::Base

  def self.sample_status_change(sample)
    # notify any services that want notifications on all samples
    find(:all, :conditions => {:sample_status_notification => true}).each do |service|
      RestClient.post service.uri, :sample => {:id => sample.id, :status => sample.status}
    end

    # notify via the postback URI for the sample if it exists
    if postback_uri = sample.postback_uri
      RestClient.post postback_uri, :sample => {:id => sample.id, :status => sample.status}
    end
  end

end
