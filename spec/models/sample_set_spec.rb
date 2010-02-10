require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSet do

  before(:each) do
    @user = mock_model(User, :login => "bmarzolf")
    User.stub(:find_by_login).with("bmarzolf").and_return(@user)

    @sample_prep_kit = create_sample_prep_kit
    @reference_genome = create_reference_genome
    @project = mock_model(Project, :lab_group => mock_model(LabGroup) )
    Project.stub!(:find).with(@project.id).and_return(@project)
    @naming_scheme = create_naming_scheme
    @naming_element = create_naming_element(:naming_scheme => @naming_scheme, :name => "Sample Key")
    @yo1 = create_naming_term(:naming_element => @naming_element, :term => "YO 1")
    @yo2 = create_naming_term(:naming_element => @naming_element, :term => "YO 2")

    # prevent RestClient from trying to hit external resources
    RestClient.stub!(:post)
  end

  describe "creating a new sample set with intialized samples" do
    it "should produce a new, valid sample set if all parameters are provided" do
      sample_set = SampleSet.new( {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
        "reference_genome_id" => @reference_genome.id.to_s,
        "project_id" => @project.id.to_s,
        "alignment_start_position" => "1",
        "alignment_end_position" => "36",
        "desired_read_length" => "36",
        "eland_parameter_set_id" => "3",
        "budget_number" => "12345678",
        "insert_size" => "100",
        "submitted_by" => "bmarzolf",
        "number_of_samples" => 2
      })

      sample_set.should be_valid
      sample_set.samples.size.should == 2
    end

    it "should not be valid if the budget number is missing" do
      sample_set = SampleSet.new( {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
        "reference_genome_id" => @reference_genome.id.to_s,
        "project_id" => @project.id.to_s,
        "alignment_start_position" => "1",
        "alignment_end_position" => "36",
        "desired_read_length" => "36",
        "eland_parameter_set_id" => "3",
        "insert_size" => "100",
        "submitted_by" => "bmarzolf",
        "number_of_samples" => 2
      })

      sample_set.should_not be_valid
    end

    it "should not be valid if the number of samples is missing" do
      sample_set = SampleSet.new( {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
        "reference_genome_id" => @reference_genome.id.to_s,
        "project_id" => @project.id.to_s,
        "alignment_start_position" => "1",
        "alignment_end_position" => "36",
        "desired_read_length" => "36",
        "eland_parameter_set_id" => "3",
        "insert_size" => "100",
        "submitted_by" => "bmarzolf",
        "budget_number" => "12345678",
        "number_of_samples" => ""
      })

      sample_set.should_not be_valid
    end
  end

  describe "using web form parameters" do
    it "should create a new sample set with valid parameters" do
      Notifier.should_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id.to_s,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
        },
        {
          "0"=>{"status"=>"", "reference_genome_id"=>@reference_genome.id.to_s,
             "name_on_tube"=>"RM11-1a pbp1::URA3", "desired_read_length"=>"36",
             "schemed_name"=>{"Sample Key"=>@yo1.id.to_s},
             "submission_date"=>"2008-10-02", "budget_number"=>"12345678", "insert_size"=>"100",
             "project_id"=>@project.id.to_s, "alignment_end_position"=>"36",
             "eland_parameter_set_id"=>"3", "submitted_by_id"=>@user.id.to_s,
             "sample_prep_kit_id"=>@sample_prep_kit.id.to_s, "naming_scheme_id"=>@naming_scheme.id.to_s},
          "1"=>{"status"=>"", "reference_genome_id"=>@reference_genome.id.to_s,
             "name_on_tube"=>"DBVPG 1373", "desired_read_length"=>"36",
             "schemed_name"=>{"Sample Key"=>@yo2.id.to_s},
             "submission_date"=>"2008-10-02", "budget_number"=>"12345678", "insert_size"=>"100",
             "project_id"=>@project.id.to_s, "alignment_end_position"=>"36",
             "eland_parameter_set_id"=>"3", "submitted_by_id"=>@user.id.to_s,
             "sample_prep_kit_id"=>@sample_prep_kit.id, "naming_scheme_id"=>@naming_scheme.id.to_s},
        }
      )
      sample_set.should be_valid
      sample_set.save
      
      new_sample_1 = Sample.find(:first, :conditions => "name_on_tube = 'RM11-1a pbp1::URA3'")
      new_sample_2 = Sample.find(:first, :conditions => "name_on_tube = 'DBVPG 1373'")

      shared_attributes = {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_prep_kit_id" => @sample_prep_kit.id,
        "reference_genome_id" => @reference_genome.id,
        "project_id" => @project.id,
        "alignment_start_position" => 1,
        "alignment_end_position" => 36,
        "desired_read_length" => 36,
        "eland_parameter_set_id" => 3,
        "budget_number" => "12345678",
        "insert_size" => 100,
        "submitted_by_id" => @user.id,
        "submission_date" => Date.parse("2008-10-02")
      }

      new_sample_1.attributes.should include(shared_attributes)
    end
  end

  describe "using JSON API parameters" do
    it "should create a new sample set with valid parametes" do
      Notifier.should_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id.to_s,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submitted_by" => "bmarzolf",
          "samples" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3",
              "Sample Key" => "YO 1",
              "postback_uri" => "http://localhost/samples/1" },
            { "name_on_tube" => "DBVPG 1373",
              "Sample Key" => "YO 2",
              "postback_uri" => "http://localhost/samples/2" }
          ]
        }
      )
      sample_set.should be_valid
      sample_set.save
      
      new_sample_1 = Sample.find(:first, :conditions => {
        :name_on_tube => 'RM11-1a pbp1::URA3',
        :postback_uri => "http://localhost/samples/1"
      })
      new_sample_2 = Sample.find(:first, :conditions => {
        :name_on_tube => 'DBVPG 1373',
        :postback_uri => "http://localhost/samples/2"
      })

      shared_attributes = {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_prep_kit_id" => @sample_prep_kit.id,
        "reference_genome_id" => @reference_genome.id,
        "project_id" => @project.id,
        "alignment_start_position" => 1,
        "alignment_end_position" => 36,
        "desired_read_length" => 36,
        "eland_parameter_set_id" => 3,
        "budget_number" => "12345678",
        "insert_size" => 100,
        "submitted_by_id" => @user.id,
      }

      new_sample_1.attributes.should include(shared_attributes)
      new_sample_2.attributes.should include(shared_attributes)
    end

    it "should not save and have an error if an invalid naming scheme is supplied" do
      Notifier.should_not_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => "1234",
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id.to_s,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submitted_by" => "bmarzolf",
          "samples" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Key" => "YO 1" },
            { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 2" }
          ]
        }
      )
      sample_set.should_not be_valid
      sample_set.errors.to_a.should == [["base",
        "The sample information seems to include meta data using a naming scheme, " +
        "but the naming scheme specified is invalid"]]
    end

    it "should not save and have an error if an incorrect naming element is provided" do
      Notifier.should_not_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id.to_s,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submitted_by" => "bmarzolf",
          "samples" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Stuff" => "YO 1" },
            { "name_on_tube" => "DBVPG 1373", "Sample Stuff" => "YO 2" }
          ]
        }
      )
      sample_set.should_not be_valid
      sample_set.errors.to_a.should == [["base",
        "Specified naming element Sample Stuff wasn't found for the naming " +
        "scheme #{@naming_scheme.name}"]]

    end

    it "should not save and have an error if the specified term is not in the controlled vocabulary" do
      Notifier.should_not_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id.to_s,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submitted_by" => "bmarzolf",
          "samples" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Key" => "YO 1" },
            { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 3" }
          ]
        }
      )
      sample_set.should_not be_valid
      sample_set.errors.to_a.should == [["base",
        "The specified term is not in the controller vocabulary for Sample Key"]]
    end

    it "should not save and have an error if an incorrect user login is given" do
      Notifier.should_not_receive(:deliver_sample_submission_notification)
      User.should_receive(:find_by_login).with("jsmith").and_raise(ActiveRecord::RecordNotFound)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submitted_by" => "jsmith",
          "samples" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3", "Sample Key" => "YO 1" },
            { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 2" }
          ]
        }
      )
      sample_set.should_not be_valid
      sample_set.errors.to_a.should == [["base",
        "The user login specified by 'submitted_by' was not found"]]
    end

    it "should create a new sample set using sample_key instead of sample_description" do
      Notifier.should_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => @sample_prep_kit.id.to_s,
          "reference_genome_id" => @reference_genome.id.to_s,
          "project_id" => @project.id.to_s,
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submitted_by" => "bmarzolf",
          "samples" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3", "sample_key" => "YO%201" },
            { "name_on_tube" => "DBVPG 1373", "sample_key" => "YO%202" }
          ]
        }
      )
      sample_set.should be_valid
      sample_set.save
      
      new_sample_1 = Sample.find(:first, :conditions =>
        "name_on_tube = 'RM11-1a pbp1::URA3' AND sample_description = 'YO%201'")
      new_sample_2 = Sample.find(:first, :conditions =>
        "name_on_tube = 'DBVPG 1373' AND sample_description = 'YO%202'")

      shared_attributes = {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "sample_prep_kit_id" => @sample_prep_kit.id,
        "reference_genome_id" => @reference_genome.id,
        "project_id" => @project.id,
        "alignment_start_position" => 1,
        "alignment_end_position" => 36,
        "desired_read_length" => 36,
        "eland_parameter_set_id" => 3,
        "budget_number" => "12345678",
        "insert_size" => 100,
        "submitted_by_id" => @user.id,
      }

      new_sample_1.attributes.should include(shared_attributes)
    end
  end

end
