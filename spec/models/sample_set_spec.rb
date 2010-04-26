require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SampleSet do

  before(:each) do
    @naming_scheme = create_naming_scheme
    @naming_element = create_naming_element(:naming_scheme => @naming_scheme, :name => "Sample Key")
    @yo1 = create_naming_term(:naming_element => @naming_element, :term => "YO 1")
    @yo2 = create_naming_term(:naming_element => @naming_element, :term => "YO 2")
    @user = mock_model(User)
    User.stub!(:find_by_login).and_return(@user)
  end

  describe "making a new sample set with JSON-style attributes" do
    before(:each) do
      @set_attributes = {
       "submission_date" => "2010-04-05",
       "number_of_samples" => 2,
       "project_id" => 1,
       "naming_scheme_id" => 1,
       "sample_prep_kit_id" => 1,
       "budget_number" => 1234,
       "reference_genome_id" => 1,
       "desired_read_length" => 36,
       "insert_size" => 100,
       "alignment_start_position" => 1,
       "alignment_end_position" => 36,
       "eland_parameter_set_id" => 1,
       "submitted_by" => "bmarzolf",
       "multiplex_number" => 1
      }
      @set_plus_mixture_attributes = @set_attributes.merge(
        "sample_mixtures" => [
          {"name_on_tube" => "A1",
           "sample_description" => "Sample Mix 1"},
          {"name_on_tube" => "A2",
           "sample_description" => "Sample Mix 2"}
        ]
      )
      @set_plus_mixture_plus_sample_attributes = @set_attributes.merge(
        "sample_mixtures" => [
          {"name_on_tube" => "A1",
           "sample_description" => "Sample Mix 1",
           "samples" => [
             {"sample_description" => "Sample 1A"},
             {"sample_description" => "Sample 1B"}
           ]},
          {"name_on_tube" => "A2",
           "sample_description" => "Sample Mix 2",
           "samples" => [
             {"sample_description" => "Sample 2A"},
             {"sample_description" => "Sample 2B"}
           ]}
        ]
      )
    end

    it "should make a new sample set without any attributes" do
      sample_set = SampleSet.new
    end

    it "should just load the sample set-level attributes if no sample mixtures are provided" do
      sample_set = SampleSet.new(@set_attributes)

      sample_set.submission_date.should == "2010-04-05"
      sample_set.number_of_samples.should == 2
      sample_set.project_id.should == 1
      sample_set.naming_scheme_id.should == 1
      sample_set.sample_prep_kit_id.should == 1
      sample_set.budget_number.should == 1234
      sample_set.reference_genome_id.should == 1
      sample_set.desired_read_length.should == 36
      sample_set.insert_size.should == 100
      sample_set.alignment_start_position.should == 1
      sample_set.alignment_end_position.should == 36
      sample_set.eland_parameter_set_id.should == 1
      sample_set.submitted_by.should == "bmarzolf"
      sample_set.multiplex_number.should == 1

      sample_set.should have(2).sample_mixtures

      sample_set.sample_mixtures[0].should have(1).samples
      sample_set.sample_mixtures[1].should have(1).samples
    end

    it "should load multi-field date" do
      sample_set = SampleSet.new(
        "submission_date(1i)" => "2010",
        "submission_date(2i)" => "04",
        "submission_date(3i)" => "05"
      )

      sample_set.submission_date.should == Date.new(2010,04,05)
    end

    it "should make sample mixtures if they are provided" do
      sample_set = SampleSet.new(@set_plus_mixture_attributes)

      sample_set.should have(2).sample_mixtures

      sample_set.sample_mixtures[0].name_on_tube.should == "A1"
      sample_set.sample_mixtures[0].sample_description.should == "Sample Mix 1"
      sample_set.sample_mixtures[1].name_on_tube.should == "A2"
      sample_set.sample_mixtures[1].sample_description.should == "Sample Mix 2"
    end

    it "should make samples if they are provided" do
      sample_set = SampleSet.new(@set_plus_mixture_plus_sample_attributes)

      sample_set.sample_mixtures[0].should have(2).samples
      sample_set.sample_mixtures[0].samples[0].sample_description.should == "Sample 1A"
      sample_set.sample_mixtures[0].samples[1].sample_description.should == "Sample 1B"
      sample_set.sample_mixtures[1].samples[0].sample_description.should == "Sample 2A"
      sample_set.sample_mixtures[1].samples[1].sample_description.should == "Sample 2B"
    end

    it "should not be valid if the budget number is missing" do
      sample_set = SampleSet.new( {
        "naming_scheme_id" => "1",
        "sample_prep_kit_id" => "1",
        "reference_genome_id" => "1",
        "project_id" => "1",
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
        "naming_scheme_id" => "1",
        "sample_prep_kit_id" => "1",
        "reference_genome_id" => "1",
        "project_id" => "1",
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

  describe "making a new sample set with form-style attributes" do
    it "should create a new sample set with valid parameters" do
      Notifier.should_receive(:deliver_sample_submission_notification)

      sample_set = SampleSet.new(
        { 
          "naming_scheme_id" => @naming_scheme.id.to_s,
          "sample_prep_kit_id" => "1",
          "reference_genome_id" => "1",
          "project_id" => "1",
          "alignment_start_position" => "1",
          "alignment_end_position" => "36",
          "desired_read_length" => "36",
          "eland_parameter_set_id" => "3",
          "budget_number" => "12345678",
          "insert_size" => "100",
          "submission_date" => "2008-10-02",
          "submitted_by" => "jsmith",
          "sample_mixtures" => {
            "0"=>{"name_on_tube"=>"RM11-1a pbp1::URA3", "sample_description" => "S1",
              "samples" => {
                "0" => { "schemed_name"=>{"Sample Key"=>"YO 1"} }
              }
            },
            "1"=>{"name_on_tube"=>"DBVPG 1373", "sample_description" => "S2",
              "samples" => {
                "0" => { "schemed_name"=>{"Sample Key"=>"YO 2"} }
              }
            }
          }
        }
      )
      sample_set.should be_valid
      
      shared_attributes = {
        "sample_prep_kit_id" => 1,
        "project_id" => 1,
        "alignment_start_position" => 1,
        "alignment_end_position" => 36,
        "desired_read_length" => 36,
        "eland_parameter_set_id" => 3,
        "budget_number" => "12345678",
        "submitted_by_id" => @user.id,
        "submission_date" => Date.parse("2008-10-02")
      }

      sample_set.sample_mixtures[0].attributes.should include(shared_attributes)
      sample_set.sample_mixtures[1].attributes.should include(shared_attributes)

      sample_set.save.should be_true
    end
  end

  describe "using the pre-multiplexing API" do
    before(:each) do
      @sample_prep_kit = create_sample_prep_kit
      @reference_genome = create_reference_genome
      @project = mock_model(Project, :lab_group => mock_model(LabGroup) )
      Project.stub!(:find_by_id).with(@project.id.to_s).and_return(@project)
    end

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
              "sample_key" => "YO1",
              "postback_uri" => "http://localhost/samples/1" },
            { "name_on_tube" => "DBVPG 1373",
              "sample_key" => "YO2",
              "postback_uri" => "http://localhost/samples/2" }
          ]
        }
      )
      sample_set.should be_valid
      sample_set.save
      
      new_sample_mixture_1 = SampleMixture.find(:first, :conditions => {
        :name_on_tube => 'RM11-1a pbp1::URA3',
      })
      new_sample_mixture_2 = SampleMixture.find(:first, :conditions => {
        :name_on_tube => 'DBVPG 1373',
      })

      shared_mixture_attributes = {
        "sample_prep_kit_id" => @sample_prep_kit.id,
        "project_id" => @project.id,
        "alignment_start_position" => 1,
        "alignment_end_position" => 36,
        "desired_read_length" => 36,
        "eland_parameter_set_id" => 3,
        "budget_number" => "12345678",
        "submitted_by_id" => @user.id,
      }
      shared_sample_attributes = {
        "naming_scheme_id" => @naming_scheme.id.to_s,
        "reference_genome_id" => @reference_genome.id,
        "insert_size" => 100,
      }

      new_sample_mixture_1.attributes.should include(shared_mixture_attributes)
      new_sample_mixture_2.attributes.should include(shared_mixture_attributes)
    end
  end
end
