require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PipelineRun do
  fixtures :site_config, :charge_templates
  
  before(:each) do
      @instrument = create_instrument(:serial_number => "HWI-EAS427")
      @flow_cell = create_flow_cell(:name => "30LD7AAXX")
      create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 5)
      create_flow_cell_lane(:flow_cell => @flow_cell, :lane_number => 6)
      @sequencing_run = create_sequencing_run(:date => "2008-11-14", :instrument => @instrument,
        :flow_cell => @flow_cell)
  end
  
  describe "making a new pipeline run with a single lane and single GERALD run" do
    
    it "should produce a valid pipeline run" do
      do_new
      @pipeline_run.should be_valid
    end

    it "should make an accompanying pipeline result record" do
      do_new
      @pipeline_run.pipeline_results.size.should == 1
    end

    it "should have the correct base directory for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
    end

    it "should have the correct summary file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm"
    end

    it "should have the correct eland output file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt"
    end
    
    it "should have the correct eland output file for an alternate eland file name" do
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_eland_result.txt")
      @pipeline_run.pipeline_results[0].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_eland_result.txt"
    end
    
    it "should create a pipeline run even when the FC is missing on the flow cell name" do
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_eland_result.txt")
      @pipeline_run.pipeline_results.size.should == 1
    end

    def do_new
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt")
    end

    it "should produce a valid pipeline run when the run folder is included in the base directory" do
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_0014_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_0014_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_0014_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt")
      @pipeline_run.should be_valid
    end
  end
  
  describe "making a new pipeline run with a single lane and two GERALD runs" do
    
    it "should produce a valid pipeline run" do
      do_new
      @pipeline_run.should be_valid
    end

    it "should make an accompanying pipeline result record" do
      do_new
      @pipeline_run.pipeline_results.size.should == 2
    end

    it "should have the correct base directory for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
      @pipeline_run.pipeline_results[1].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
    end

    it "should have the correct summary file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm"
      @pipeline_run.pipeline_results[1].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/Summary.htm"
    end

    it "should have the correct eland output file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt"
      @pipeline_run.pipeline_results[1].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/s_5_export.txt"
    end
    
    def do_new
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/Summary.htm",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/s_5_export.txt"
      )
    end
  end
    
  describe "making a new pipeline run with two lanes and two GERALD runs" do
    
    it "should produce a valid pipeline run" do
      do_new
      @pipeline_run.should be_valid
    end

    it "should make an accompanying pipeline result record" do
      do_new
      @pipeline_run.pipeline_results.size.should == 4
    end

    it "should have the correct base directory for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
      @pipeline_run.pipeline_results[1].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
    end

    it "should have the correct summary file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm"
      @pipeline_run.pipeline_results[1].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm"
      @pipeline_run.pipeline_results[2].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/Summary.htm"
      @pipeline_run.pipeline_results[3].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/Summary.htm"
    end

    it "should have the correct eland output file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt"
      @pipeline_run.pipeline_results[1].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_6_export.txt"
      @pipeline_run.pipeline_results[2].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/s_5_export.txt"
      @pipeline_run.pipeline_results[3].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/s_6_export.txt"
    end
    
    def do_new
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/Summary.htm",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_export.txt," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_6_export.txt," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/s_5_export.txt," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_19-11-2008_kdeutsch/s_6_export.txt"
      )
    end
  end
    
  describe "making a new pipeline run with paired end results" do
    
    it "should produce a valid pipeline run" do
      do_new
      @pipeline_run.should be_valid
    end

    it "should make an accompanying pipeline result record" do
      do_new
      @pipeline_run.pipeline_results.size.should == 2
    end

    it "should have the correct base directory for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
      @pipeline_run.pipeline_results[1].base_directory.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX"
    end

    it "should have the correct summary file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm"
      @pipeline_run.pipeline_results[1].summary_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm"
    end

    it "should have the correct eland output file for the pipeline result" do
      do_new
      @pipeline_run.pipeline_results[0].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_1_export.txt"
      @pipeline_run.pipeline_results[1].eland_output_file.should == 
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_2_export.txt"
    end
    
    def do_new
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm,",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_1_export.txt," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5_2_export.txt"
      )
    end
  end

  describe "making a new pipeline run with an invalid eland output file name" do
    
    it "should raise an error" do
      lambda {do_new}.should raise_error
    end

    def do_new
      @pipeline_run = PipelineRun.new(
      :base_directory => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX",
      :summary_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data/" +
        "IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/Summary.htm,",
      :eland_output_files => "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_5a_export.txt," +
        "/solexa/facility/PhiX/081114_HWI-EAS427_FC30LD7AAXX/Data" +
        "/IPAR_1.01/Bustard1.9.5_17-11-2008_kdeutsch/GERALD_17-11-2008_kdeutsch/s_6_export.txt"
      )
    end
  end
end
