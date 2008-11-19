require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCellLane do
  it "should mark samples as clustered" do
    sample_1 = create_sample
    sample_2 = create_sample
    flow_cell_lane = create_flow_cell_lane(:samples => [sample_1, sample_2])
    
    flow_cell_lane.mark_samples_as_clustered
    sample_1.reload.status.should == "clustered"
    sample_2.reload.status.should == "clustered"
  end
  
  it "should mark samples as submitted" do
    sample_1 = create_sample(:status => "clustered")
    sample_2 = create_sample(:status => "clustered")
    flow_cell_lane = create_flow_cell_lane(:samples => [sample_1, sample_2])
    
    flow_cell_lane.mark_samples_as_submitted
    sample_1.reload.status.should == "submitted"
    sample_2.reload.status.should == "submitted"
  end
  
  # lots of mocks here due to interconnectedness of these models
  describe "being sequenced" do
    before(:each) do
      @lab_group = create_lab_group(:file_folder => "Yeast")
      @project = create_project(:lab_group => @lab_group, :file_folder => "Genetics")
      @sample_1 = create_sample(:project => @project)
      @sample_2 = create_sample(:project => @project)

      @instrument = create_instrument(:serial_number => "HWI-234234")
      @sequencing_run = mock_model(SequencingRun)
      @sequencing_run.stub!(:date_yymmdd).and_return("081010")
      @sequencing_run.stub!(:instrument).and_return(@instrument)

      @flow_cell = mock_model(FlowCell)
      @flow_cell.stub!(:name).and_return("123ABC")
      @flow_cell.stub!(:sequencing_run).twice.and_return(@sequencing_run)

      @flow_cell_lane = create_flow_cell_lane(:samples => [@sample_1, @sample_2],
                                             :flow_cell => @flow_cell)

      # if charge tracking is turned on, sequencing should result in a new charge
      @charge_set = create_charge_set(:name => @sample_1.project.name,
                                     :lab_group => @lab_group,
                                     :budget => @sample_1.budget_number,
                                     :charge_period => create_charge_period)
      @charge_template = create_charge_template(:default => true)
      ChargeSet.stub!(:find_or_create_for_latest_charge_period).and_return(@charge_set)
      Charge.stub!(:create)
    end
    
    it "should change the associated sample statuses to 'sequenced'" do
      @flow_cell_lane.sequence!

      # can't figure out how to check that 'sequence!' was called for each sample, so just
      # check sample status directly
      @sample_1.reload.status.should == "sequenced"
      @sample_2.reload.status.should == "sequenced"
    end
    
    it "should set the raw data path" do
      @sequencing_run.should_receive(:date_yymmdd).and_return("081010")
      @sequencing_run.should_receive(:instrument).and_return(@instrument)
      @flow_cell.should_receive(:name).and_return("123ABC")
      @flow_cell.should_receive(:sequencing_run).twice.and_return(@sequencing_run)
      
      @flow_cell_lane.sequence!
      
      @flow_cell_lane.raw_data_path.should == "/Yeast/Genetics/081010_HWI-234234_123ABC"      
    end
    
    it "should record the appropriate charge if the sample isn't a control" do
      ChargeSet.should_receive(:find_or_create_for_latest_charge_period).
        with(@sample_1.project, @sample_1.budget_number).and_return(@charge_set)
      Charge.should_receive(:create).with(
        :charge_set => @charge_set,
        :date => Date.today,
        :description => "#{@sample_1.name_on_tube}, #{@sample_2.name_on_tube}",
        :cost => @charge_template.cost)
      
      @flow_cell_lane.sequence!
    end

    it "should not record a charge if the sample is a control" do
      @sample_1.reload.update_attribute('control', true)
      ChargeSet.should_not_receive(:find_or_create_for_latest_charge_period)
      Charge.should_not_receive(:create)
      
      @flow_cell_lane.sequence!
    end

  end
  
  it "should handle being 'unsequenced'" do
    sample_1 = create_sample(:status => "sequenced")
    sample_2 = create_sample(:status => "sequenced")
    
    flow_cell_lane = create_flow_cell_lane(:samples => [sample_1, sample_2],
                                           :raw_data_path => "/path/to/data")

    flow_cell_lane.unsequence!
    flow_cell_lane.raw_data_path.should == ""
    
    # can't figure out how to check that 'sequence!' was called for each sample, so just
    # check the status directly
    sample_1.reload.status.should == "clustered"
    sample_2.reload.status.should == "clustered"
  end
  
  it "should provide a hash of summary attributes" do
    flow_cell_lane = create_flow_cell_lane(:lane_number => 1)
    
    flow_cell_lane.summary_hash.should == {
      :id => flow_cell_lane.id,
      :lane_number => 1,
      :flow_cell_uri => "http://example.com/flow_cells/#{flow_cell_lane.flow_cell_id}",
      :updated_at => flow_cell_lane.updated_at,
      :uri => "http://example.com/flow_cell_lanes/#{flow_cell_lane.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    sample_1 = create_sample
    sample_2 = create_sample
    
    flow_cell_lane = create_flow_cell_lane(
      :lane_number => 1,
      :comment => "failed",
      :starting_concentration => 1000,
      :loaded_concentration => 2,
      :raw_data_path => "/path/to/data",
      :samples => [sample_1, sample_2]
    )   

    flow_cell_lane.detail_hash.should == {
      :id => flow_cell_lane.id,
      :lane_number => 1,
      :flow_cell_uri => "http://example.com/flow_cells/#{flow_cell_lane.flow_cell_id}",
      :updated_at => flow_cell_lane.updated_at,
      :comment => "failed",
      :status => "clustered",
      :starting_concentration => 1000,
      :loaded_concentration => 2,
      :raw_data_path => "",
      :sample_uris => ["http://example.com/samples/#{sample_1.id}",
                       "http://example.com/samples/#{sample_2.id}"]
    }
  end
end
