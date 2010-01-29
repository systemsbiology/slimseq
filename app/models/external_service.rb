class ExternalService < ActiveRecord::Base

  def self.sample_status_change(sample)
    find(:all, :conditions => {:sample_status_notification => true}).each do |service|
      RestClient.post service.uri, :sample => {:id => sample.id, :status => sample.status}
    end
  end

end
