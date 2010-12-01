require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSet do

  before(:each) do
    @naming_scheme = create_naming_scheme
    @naming_element = create_naming_element(:naming_scheme => @naming_scheme, :name => "Sample Key")
    @yo1 = create_naming_term(:naming_element => @naming_element, :term => "YO 1", :abbreviated_term => "YO1")
    @yo2 = create_naming_term(:naming_element => @naming_element, :term => "YO 2", :abbreviated_term => "YO2")
    @user = mock_model(User, :login => "bsmith")
    User.stub!(:find_by_login).and_return(@user)
    @platform = create_platform
    Platform.stub!(:find_by_id).and_return(@platform)
    @primer = create_primer
  end

  #describe "making a new sample set with JSON-style attributes" do
  #  before(:each) do
  #    @set_attributes = {
  #     "platform_id" => 1,
  #     "submission_date" => "2010-04-05",
  #     "number_of_samples" => 2,
  #     "project_id" => 1,
  #     "naming_scheme_id" => 1,
  #     "sample_prep_kit_id" => 1,
  #     "budget_number" => 1234,
  #     "reference_genome_id" => 1,
  #     "desired_read_length" => 36,
  #     "insert_size" => 100,
  #     "alignment_start_position" => 1,
  #     "alignment_end_position" => 36,
  #     "eland_parameter_set_id" => 1,
  #     "submitted_by" => "bmarzolf",
  #     "multiplex_number" => 1
  #    }
  #    @set_plus_mixture_attributes = @set_attributes.merge(
  #      "sample_mixtures" => [
  #        {"name_on_tube" => "A1",
  #         "sample_description" => "Sample Mix 1"},
  #        {"name_on_tube" => "A2",
  #         "sample_description" => "Sample Mix 2"}
  #      ]
  #    )
  #    @set_plus_mixture_plus_sample_attributes = @set_attributes.merge(
  #      "sample_mixtures" => [
  #        {"name_on_tube" => "A1",
  #         "sample_description" => "Sample Mix 1",
  #         "samples" => [
  #           {"sample_description" => "Sample 1A"},
  #           {"sample_description" => "Sample 1B"}
  #         ]},
  #        {"name_on_tube" => "A2",
  #         "sample_description" => "Sample Mix 2",
  #         "samples" => [
  #           {"sample_description" => "Sample 2A"},
  #           {"sample_description" => "Sample 2B"}
  #         ]}
  #      ]
  #    )
  #  end

  describe "making a new sample set with parameters parameters submitted from the HTML form" do
    context "with a single read" do
      context "with a standard prep kit and primer" do
        it "creates a new sample set" do
          Notifier.should_receive(:deliver_sample_submission_notification)

          sample_set = SampleSet.parse_api( 
            { 
              "alignment_start_position" => "1",
              "alignment_start_position_1" => "",
              "alignment_start_position_2" => "",
              "alignment_end_position" => "72",
              "alignment_end_position_1" => "",
              "alignment_end_position_2" => "",
              "budget_number" => "12345678",
              "custom_prep_kit_id" => "",
              "custom_prep_kit_name" => "",
              "custom_prep_kit_comments" => "",
              "custom_primer_kit_id" => "",
              "custom_primer_kit_name" => "",
              "custom_primer_kit_comments" => "",
              "date(1i)" => "2010",
              "date(2i)" => "11",
              "date(3i)" => "19",
              "desired_read_length" => "72",
              "desired_read_length_1" => "",
              "desired_read_length_2" => "",
              "eland_parameter_set_id" => "3",
              "insert_size" => "200",
              "multiplexing_scheme_id" => "",
              "multiplexed_number" => "",
              "naming_scheme_id" => @naming_scheme.id,
              "next_step" => "samples",
              "number" => "2",
              "platform_id" => @platform.id,
              "primer_id" => @primer.id,
              "project_id" => "1",
              "read_format" => "Single read",
              "reference_genome_id" => "1",
              "sample_mixtures" => {
                "0"=>{"name_on_tube"=>"RM11-1a pbp1::URA3", "sample_description" => "S1",
                  "samples" => {
                    "0" => { "schemed_name"=>{"SampleKey"=>"YO 1"} }
                  }
                },
                "1"=>{"name_on_tube"=>"DBVPG 1373", "sample_description" => "S2",
                  "samples" => {
                    "0" => { "schemed_name"=>{"SampleKey"=>"YO 2"} }
                  }
                }
              },
              "sample_prep_kit_id" => "1",
              "submitted_by_id" => @user.id
            }
          )
          debugger
          sample_set.should be_valid
          
          shared_mixture_attributes = {
            "budget_number" => "12345678",
            "eland_parameter_set_id" => 3,
            "platform_id" => @platform.id,
            "primer_id" => @primer.id,
            "project_id" => 1,
            "sample_prep_kit_id" => 1,
            "submitted_by_id" => @user.id,
            "submission_date" => Date.parse("2010-11-19")
          }
          shared_sample_attributes = {
            "insert_size" => 200,
            "reference_genome_id" => 1
          }
          shared_read_attributes = {
            "alignment_start_position" => 1,
            "alignment_end_position" => 72,
            "desired_read_length" => 72
          }

          sample_set.sample_mixtures[0].attributes.should include(shared_mixture_attributes)
          sample_set.sample_mixtures[0].sample_description.should == "S1"
          sample_set.sample_mixtures[1].attributes.should include(shared_mixture_attributes)
          sample_set.sample_mixtures[1].sample_description.should == "S2"

          sample_set.sample_mixtures[0].samples[0].attributes.should include(shared_sample_attributes)
          sample_set.sample_mixtures[0].samples[0].sample_description.should == "YO1"
          sample_set.sample_mixtures[1].samples[0].attributes.should include(shared_sample_attributes)
          sample_set.sample_mixtures[1].samples[0].sample_description.should == "YO2"

          sample_set.sample_mixtures[0].desired_reads[0].attributes.should include(shared_read_attributes)
          sample_set.sample_mixtures[1].desired_reads[0].attributes.should include(shared_read_attributes)

          sample_set.save.should be_true
        end
      end
    end
  end

  describe "using the API" do
    before(:each) do
      @sample_prep_kit = create_sample_prep_kit
      @reference_genome = create_reference_genome
      @project = mock_model(Project, :lab_group => mock_model(LabGroup) )
      Project.stub!(:find_by_id).with(@project.id.to_s).and_return(@project)
    end

    it "should create a new sample set with valid parameters" do
      Notifier.should_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.parse_api(
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
          "submitted_by" => @user.login,
          "read_format" => "Single read",
          "primer_id" => @primer.id,
          "platform_id" => @platform.id,
          "sample_mixtures" => [
            { "name_on_tube" => "RM11-1a pbp1::URA3",
              "sample_description" => "YO1",
              "postback_uri" => "http://localhost/samples/1" },
            { "name_on_tube" => "DBVPG 1373",
              "sample_description" => "YO2",
              "postback_uri" => "http://localhost/samples/2" }
          ]
        }
      )

      sample_set.should be_valid
      sample_set.save
      
      shared_mixture_attributes = {
        "sample_prep_kit_id" => @sample_prep_kit.id,
        "project_id" => @project.id,
        "eland_parameter_set_id" => 3,
        "budget_number" => "12345678",
        "submitted_by_id" => @user.id,
      }
      shared_sample_attributes = {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "reference_genome_id" => @reference_genome.id,
        "insert_size" => 100,
      }
      shared_read_attributes = {
        "alignment_start_position" => 1,
        "alignment_end_position" => 36,
        "desired_read_length" => 36
      }

      sample_set.sample_mixtures[0].attributes.should include(shared_mixture_attributes)
      sample_set.sample_mixtures[0].sample_description.should == "YO1"
      sample_set.sample_mixtures[1].attributes.should include(shared_mixture_attributes)
      sample_set.sample_mixtures[1].sample_description.should == "YO2"

      sample_set.sample_mixtures[0].samples[0].attributes.should include(shared_sample_attributes)
      sample_set.sample_mixtures[0].samples[0].sample_description.should == "YO1"
      sample_set.sample_mixtures[1].samples[0].attributes.should include(shared_sample_attributes)
      sample_set.sample_mixtures[1].samples[0].sample_description.should == "YO2"

      sample_set.sample_mixtures[0].desired_reads[0].attributes.should include(shared_read_attributes)
      sample_set.sample_mixtures[1].desired_reads[0].attributes.should include(shared_read_attributes)
    end
  end
end
