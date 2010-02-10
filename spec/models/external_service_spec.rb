require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExternalService do

  it "should notify appropriate external services of a sample status change notification" do
    service_1 = create_external_service(:uri => "http://localhost:4567/done")
    service_2 = create_external_service(:sample_status_notification => false)
    sample = mock_model(Sample, :status => "completed", :postback_uri => "http://localhost:4568/samples/1")

    RestClient.should_receive(:post).with("http://localhost:4567/done",
      :sample => {:id => sample.id, :status => "completed"})

    RestClient.should_receive(:post).with("http://localhost:4568/samples/1",
      :sample => {:id => sample.id, :status => "completed"})

    ExternalService.sample_status_change(sample)
  end

end
