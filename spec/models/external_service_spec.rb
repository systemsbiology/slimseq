require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExternalService do
  describe "for a sample status change notification" do
    it "should notify appropriate external services using JSON-wrapped data and in-JSON authentication" do
      # need to stub for the first call that happens when the sample is created
      RestClient.stub!(:post)

      service_1 = create_external_service(:uri => "http://localhost:4567/done")
      service_2 = create_external_service(:uri => "http://localhost:4567/samples", :sample_status_notification => false,
        :username => "bob", :password => "1234", :authentication => true)
      sample_mixture = create_sample_mixture
      sample = create_sample(:postback_uri => "http://localhost:4567/samples/1",
        :sample_description => "YO1", :sample_mixture => sample_mixture)
      flow_cell = create_flow_cell(:name => "123ABCD")
      lane = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell)
      pipeline_result = create_pipeline_result(:flow_cell_lane => lane, :summary_file => "/path/to/summary.file",
        :eland_output_file => "/path/to/eland.file")

      # TODO: Figure out a little brittle way to do these tests
      #RestClient.should_receive(:post).with(
      #  "http://localhost:4567/done", "JSON={'status':'submitted','raw_data_path':'/path/to/eland.file','sample_description':'YO1','summary_path':'/path/to/summary.file','flow_cell_name':'123ABC','lane':1,'id':#{sample.id}}"
      #) 
      #RestClient.should_receive(:post).with(
      #  "http://localhost:4567/samples/1", "JSON={'status':'submitted','raw_data_path':'/path/to/eland.file','sample_description':'YO1','summary_path':'/path/to/summary.file','username':'bob','flow_cell_name':'123ABC','password':'1234','lane':1}"
      #)

      ExternalService.sample_status_change(sample)
    end

    it "should log an error if connecting to an external service fails" do
      # need to stub for the first call that happens when the sample is created
      RestClient.stub!(:post)
      
      service_1 = create_external_service(:uri => "http://localhost:4567/done")
      sample_mixture = create_sample_mixture
      sample = create_sample(:postback_uri => "http://localhost:4567/samples/1",
        :sample_description => "YO1", :sample_mixture => sample_mixture)
      flow_cell = create_flow_cell(:name => "123ABCD")
      lane = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell)
      pipeline_result = create_pipeline_result(:flow_cell_lane => lane, :summary_file => "/path/to/summary.file",
        :eland_output_file => "/path/to/eland.file")
      
      RestClient.should_receive(:post).and_raise(Errno::ECONNREFUSED)

      lambda {ExternalService.sample_status_change(sample)}.should_not raise_error
    end

    it "should log an error if connecting to an external service raises RestClient::RequestFailed" do
      service_1 = create_external_service(:uri => "http://localhost:4567/done")
      sample = create_sample(:sample_description => "YO1")
      flow_cell = create_flow_cell(:name => "123ABCD")
      sample_mixture = create_sample_mixture
      lane = create_flow_cell_lane(:sample_mixture => sample_mixture, :flow_cell => flow_cell)
      pipeline_result = create_pipeline_result(:flow_cell_lane => lane, :summary_file => "/path/to/summary.file",
        :eland_output_file => "/path/to/eland.file")
      
      RestClient.should_receive(:post).and_raise(RestClient::RequestFailed)

      lambda {ExternalService.sample_status_change(sample)}.should_not raise_error
    end
  end
end
