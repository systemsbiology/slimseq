require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExternalService do
  describe "for a sample status change notification" do
    it "should notify appropriate external services" do
      service_1 = create_external_service(:uri => "http://localhost:4567/done")
      service_2 = create_external_service(:sample_status_notification => false)
      sample_mixture = mock_model(SampleMixture, :status => "completed")
      sample = mock_model(Sample, :postback_uri => "http://localhost:4568/samples/1",
        :sample_mixture => sample_mixture)

      RestClient.should_receive(:post).with("http://localhost:4567/done",
        "{\"sample\":{\"status\":\"completed\",\"id\":#{sample.id}}}", {:content_type=>:json, :accept=>:json})

      RestClient.should_receive(:post).with("http://localhost:4568/samples/1",
        "{\"sample\":{\"status\":\"completed\",\"id\":#{sample.id}}}", {:content_type=>:json, :accept=>:json})

      ExternalService.sample_status_change(sample)
    end

    it "should log an error if connecting to an external service fails" do
      service_1 = create_external_service(:uri => "http://localhost:4567/done")
      sample_mixture = mock_model(SampleMixture, :status => "completed")
      sample = mock_model(Sample, :postback_uri => "http://localhost:4568/samples/1",
        :sample_mixture => sample_mixture)
      
      RestClient.should_receive(:post).with("http://localhost:4567/done",
        "{\"sample\":{\"status\":\"completed\",\"id\":#{sample.id}}}", {:content_type=>:json, :accept=>:json}).
        and_raise(Errno::ECONNREFUSED)

      lambda {ExternalService.sample_status_change(sample)}.should_not raise_error
    end
  end
end
