require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSet do

  before(:each) do
    @user = mock_model(User)
    User.stub(:find_by_login).with("bmarzolf").and_return(@user)

    @sample_prep_kit = create_sample_prep_kit
    @reference_genome = create_reference_genome
    @project = create_project
    @naming_scheme = create_naming_scheme
    @naming_element = create_naming_element(:naming_scheme => @naming_scheme, :name => "Sample Key")
    @yo1 = create_naming_term(:naming_element => @naming_element, :term => "YO 1")
    @yo2 = create_naming_term(:naming_element => @naming_element, :term => "YO 2")
  end

  it "should create a new sample set with valid parametes" do
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
          { "name_on_tube" => "DBVPG 1373", "Sample Key" => "YO 2" }
        ]
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
    }

    new_sample_1.attributes.should include(shared_attributes)
  end

  it "should not save and have an error if an invalid naming scheme is supplied" do
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
    sample_set.errors.should == ["The sample information seems to include meta data using a naming scheme, " +
      "but the naming scheme specified is invalid"]
  end

  it "should not save and have an error if an incorrect naming element is provided" do
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
    sample_set.errors.should == ["Specified naming element Sample Stuff wasn't found for the naming " +
              "scheme #{@naming_scheme.name}"]

  end

  it "should not save and have an error if the specified term is not in the controlled vocabulary" do
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
    sample_set.errors.should == ["The specified term is not in the controller vocabulary for Sample Key"]
  end

  it "should not save and have an error if an incorrect user login is given" do
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
    sample_set.errors.should == ["The user login specified by 'submitted_by' was not found"]
  end

end
