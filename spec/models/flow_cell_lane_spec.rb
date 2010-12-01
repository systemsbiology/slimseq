require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCellLane do
  fixtures :site_config
  
  it "should mark samples as clustered" do
    mixture = create_sample_mixture(:status => "sequenced")
    flow_cell_lane = create_flow_cell_lane(:sample_mixture => mixture)
    
    flow_cell_lane.mark_sample_mixture_as_clustered

    mixture.reload.status.should == "clustered"
  end
  
  it "should mark samples as submitted" do
    mixture = create_sample_mixture(:status => "sequenced")
    flow_cell_lane = create_flow_cell_lane(:sample_mixture => mixture)
    
    flow_cell_lane.mark_sample_mixture_as_submitted

    mixture.reload.status.should == "submitted"
  end
  
  it "should mark the sample mixture as sequenced" do
    mixture = create_sample_mixture
    flow_cell_lane = create_flow_cell_lane(:sample_mixture => mixture)

    flow_cell_lane.sequence!

    mixture.reload.status.should == "sequenced"
  end
  
  it "should handle being 'unsequenced'" do
    mixture = create_sample_mixture(:status => "sequenced")
    
    flow_cell_lane = create_flow_cell_lane(:sample_mixture => mixture)

    flow_cell_lane.unsequence!
    
    mixture.reload.status.should == "clustered"
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
    mixture = create_sample_mixture( :samples => [sample_1, sample_2] )
    
    flow_cell_lane = create_flow_cell_lane(
      :lane_number => 1,
      :comment => "failed",
      :starting_concentration => 1000,
      :loaded_concentration => 2,
      :sample_mixture => mixture,
      :lane_yield_kb => 4200,
      :average_clusters => 20000,
      :percent_pass_filter_clusters => 60,
      :percent_align => 50,
      :percent_error => 20
    )   

    flow_cell_lane.detail_hash.should == {
      :id => flow_cell_lane.id,
      :lane_number => 1,
      :flow_cell_uri => "http://example.com/flow_cells/#{flow_cell_lane.flow_cell_id}",
      :flow_cell_name => flow_cell_lane.flow_cell.prefixed_name,
      :updated_at => flow_cell_lane.updated_at,
      :comment => "failed",
      :status => "clustered",
      :starting_concentration => 1000,
      :loaded_concentration => 2,
      :raw_data_path => nil,
      :eland_output_files => nil,
      :summary_file => nil,
      :sequencer => {},
      :lane_yield_kb => 4200,
      :average_clusters => 20000,
      :percent_pass_filter_clusters => 60.0,
      :percent_align => 50.0,
      :percent_error => 20.0,
      :sample_uris => ["http://example.com/samples/#{sample_1.id}",
                       "http://example.com/samples/#{sample_2.id}"]
    }
  end

  describe "providing the raw data path" do
    
    it "should provide a path if an associated pipeline result exists" do
      lane = create_flow_cell_lane
      result = create_pipeline_result(:flow_cell_lane => lane)
      lane.should_receive(:pipeline_results).twice.
        and_return( pipeline_results = mock("Pipeline Results") )
      pipeline_results.should_receive(:size).and_return(1)
      pipeline_results.should_receive(:find).with(:first, :order => "gerald_date DESC").
        and_return(result)
      lane.raw_data_path.should == result.base_directory
    end

    it "should return nil if there are no associated results" do
      lane = create_flow_cell_lane
      result = create_pipeline_result(:flow_cell_lane => lane)
      lane.should_receive(:pipeline_results).
        and_return( pipeline_results = mock("Pipeline Results") )
      pipeline_results.should_receive(:size).and_return(0)
      lane.raw_data_path.should be_nil
    end

  end

  describe "setting the raw data path" do

    it "should update an existing pipeline result if there is one" do
      lane = create_flow_cell_lane
      result = create_pipeline_result(:flow_cell_lane => lane)
      lane.should_receive(:pipeline_results).twice.
        and_return( pipeline_results = mock("Pipeline Results") )
      pipeline_results.should_receive(:size).and_return(1)
      pipeline_results.should_receive(:find).with(:first, :order => "gerald_date DESC").
        and_return(result)
      result.should_receive(:update_attribute).with('base_directory', '/path/to/data')
      lane.raw_data_path = "/path/to/data"
    end

    it "should do nothing if no pipeline result exists" do
      lane = create_flow_cell_lane
      lane.raw_data_path = "/path/to/data"
    end
  end

  it "should provide the default result path" do
    lab_group = mock_model(LabGroup)
    lab_group_profile = create_lab_group_profile(:file_folder => "genetics", :lab_group_id => lab_group.id)
    project = create_project(:lab_group_id => lab_group.id, :file_folder => "mouse")
    sample_mixture = create_sample_mixture(:project => project)
    flow_cell = create_flow_cell(:name => "2233AAXX")
    lane = create_flow_cell_lane(:flow_cell => flow_cell, :sample_mixture => sample_mixture)
    instrument = create_instrument(:serial_number => "HWI-EAS123")
    sequencing_run = create_sequencing_run(:flow_cell => flow_cell, :instrument => instrument,
                                           :date => "2009-07-22")

    lane.default_result_path.should == "/solexa/genetics/mouse/090722_HWI-EAS123_FC2233AAXX"
  end

  it "should use the provided number of cycles" do
    mixture = create_sample_mixture
    lane = create_flow_cell_lane(:sample_mixture => mixture, :actual_reads => [create_actual_read])
    lane.actual_reads.first.number_of_cycles.should == 50
  end

  it "should use the desired read length from the sample mixture if number of cycles isn't provided" do
    mixture = create_sample_mixture
    lane = create_flow_cell_lane(:sample_mixture => mixture)
    lane.actual_reads.first.number_of_cycles.should == 36
  end

  describe "producing a USE_BASES string for Gerald" do
    context "with a single read" do
      context "desired read length matches the number of cycles on the lane" do
        context "last base skipping turned off" do
          it "returns 'Y36' if the alignment start and stop span the full desired read" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 1, :alignment_end_position => 36, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(false).should == "Y36"
          end
          
          it "provides 'Y25n11' for the first 25 of 36 bases of the desired read length" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 1, :alignment_end_position => 25, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(false).should == "Y25n11"
          end
          
          it "provides 'n2Y34' for the last 34 of 36 bases of the desired read length" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 3, :alignment_end_position => 36, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(false).should == "n2Y34"
          end

          it "provides 'n4Y15n17' for the 5th through 19th bases of a 36 base read" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 5, :alignment_end_position => 19, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(false).should == "n4Y15n17"
          end
        end

        context "with last base skipping turned on" do
          it "provides 'Y35n' if the alignment start and stop span the full desired read" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 1, :alignment_end_position => 36, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(true).should == "Y35n1"
          end
          
          it "provides 'Y25n11' for the first 25 of 36 bases of the desired read length" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 1, :alignment_end_position => 25, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(true).should == "Y25n11"
          end
          
          it "provides 'n2Y33n1' for the last 34 of 36 bases of the desired read length" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 3, :alignment_end_position => 36, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(true).should == "n2Y33n1"
          end

          it "provides 'n4Y15n17' for the 5th through 19th bases of a 36 base read" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 5, :alignment_end_position => 19, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(true).should == "n4Y15n17"
          end
        end

        context "when the alignment end position is greater than the desired read length" do
          it "should use the read length as the alignment end position" do
            mixture = new_sample_mixture(
              :desired_reads => [create_desired_read(
                :alignment_start_position => 5, :alignment_end_position => 41, :desired_read_length => 36)] )
            lane = create_flow_cell_lane(:sample_mixture => mixture,
              :actual_reads => [create_actual_read(:number_of_cycles => 36)] )
            lane.use_bases_string(true).should == "n4Y31n1"
          end
        end
      end

      context "with number of cycles not matching desired read length" do
        it "should override the sample alignement start and stop" do
          mixture = new_sample_mixture(
            :desired_reads => [create_desired_read(
              :alignment_start_position => 5, :alignment_end_position => 19, :desired_read_length => 36)] )
          lane = create_flow_cell_lane(:sample_mixture => mixture,
            :actual_reads => [create_actual_read(:number_of_cycles => 40)] )
          lane.use_bases_string(true).should == "Y39n1"
        end
      end
    end

    context "with paired end reads" do
      it "provides 'Y35n,Y35n' for paired 36bp reads" do
        mixture = new_sample_mixture(
          :desired_reads => [
            create_desired_read(:alignment_start_position => 1, :alignment_end_position => 36, :desired_read_length => 36),
            create_desired_read(:alignment_start_position => 1, :alignment_end_position => 36, :desired_read_length => 36, :read_order => 2)
        ] )
        lane = create_flow_cell_lane(:sample_mixture => mixture,
          :actual_reads => [create_actual_read(:number_of_cycles => 36), create_actual_read(:number_of_cycles => 36, :read_order => 2)] )
        lane.use_bases_string(true).should == "Y35n1,Y35n1"
      end

      it "provides 'Y79n,Y39n' for 80/40 reads" do
        mixture = new_sample_mixture(
          :desired_reads => [
            create_desired_read(:alignment_start_position => 1, :alignment_end_position => 80, :desired_read_length => 80),
            create_desired_read(:alignment_start_position => 1, :alignment_end_position => 40, :desired_read_length => 40, :read_order => 2)
        ] )
        lane = create_flow_cell_lane(:sample_mixture => mixture,
          :actual_reads => [create_actual_read(:number_of_cycles => 80), create_actual_read(:number_of_cycles => 40, :read_order => 2)] )
        lane.use_bases_string(true).should == "Y79n1,Y39n1"
      end
    end
  end

end
