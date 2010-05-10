class ExternalService < ActiveRecord::Base

  def self.sample_status_change(sample)
    begin
      # notify any services that want notifications on all samples
      find(:all, :conditions => {:sample_status_notification => true}).each do |service|
        service.post_sample(sample, service.uri, true) if service.sample_status_notification
      end

      # notify via the postback URI for the sample if it exists
      if postback_uri = sample.postback_uri
        find(:all).each do |service|
          # only notify services that have a base URI that is a subset of the postback URI
          next unless postback_uri.include? service.uri

          service.post_sample(sample, postback_uri, false)
        end
      end
    rescue Errno::ECONNREFUSED, RestClient::RequestFailed, RestClient::ResourceNotFound => e
      logger.error "Connection refused for external service notification on sample id #{sample.id}"
    end
  end

  def post_sample(sample, postback_uri, include_id=true)
    # use latest flow cell lane and pipeline results
    lane = sample.sample_mixture.flow_cell_lanes.last
    result = lane.pipeline_results.last if lane

    postback_body = ""
    postback_body += "JSON=" if json_style == "JSON-wrapped"
    json_attributes = {
      :sample_description => sample.sample_description,
      :status => sample.sample_mixture.status
    }
    if include_id
      json_attributes.merge!({:id => sample.id})
    end
    if lane
      json_attributes.merge!({:flow_cell_name => lane.flow_cell.name, :lane => lane.lane_number})
    end
    if authentication && authentication_method == "in-JSON"
      json_attributes.merge!({:username => username, :password => password})
    end
    if result
      json_attributes.merge!({:raw_data_path => result.eland_output_file, :summary_path => result.summary_file})
    end
    postback_body += json_attributes.to_json
    postback_body.gsub!(/\"/, "'")

    logger.info "POST to #{postback_uri} with body: #{postback_body}"
    RestClient.post postback_uri, postback_body #, :content_type => :json, :accept => :json
  end

end
