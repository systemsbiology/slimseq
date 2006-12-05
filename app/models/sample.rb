class Sample < ActiveRecord::Base
  has_one :hybridization, :dependent => :destroy

  belongs_to :chip_type
  belongs_to :project
  belongs_to :starting_quality_trace, :class_name => "QualityTrace", :foreign_key => "starting_quality_trace_id"
  belongs_to :amplified_quality_trace, :class_name => "QualityTrace", :foreign_key => "amplified_quality_trace_id"
  belongs_to :fragmented_quality_trace, :class_name => "QualityTrace", :foreign_key => "fragmented_quality_trace_id"
  
  validates_associated :chip_type, :project
  validates_presence_of :sample_name, :short_sample_name, :submission_date, :project_id
#  validates_uniqueness_of :sample_name
  validates_length_of :short_sample_name, :maximum => 20
  validates_length_of :sample_name, :maximum => 59
  validates_length_of :sbeams_user, :maximum => 20
  validates_length_of :status, :maximum => 50
  
  def validate_on_create
    # make sure date/short_sample_name/sample_name combo is unique
    if Sample.find_by_submission_date_and_short_sample_name_and_sample_name(
              submission_date, short_sample_name, sample_name)
      errors.add("Duplicate submission date/short_sample_name/sample_name")
    end
    
    # look for all the things that infuriate GCOS or SBEAMS:
    # * non-existent sample name
    # * spaces
    # * characters other than underscores and dashes
    if sample_name == nil
      errors.add("Sample name must be supplied")
    elsif sample_name[/\ /] != nil ||
       sample_name[/\+/] != nil ||
       sample_name[/\&/] != nil ||
       sample_name[/\#/] != nil ||
       sample_name[/\(/] != nil ||
       sample_name[/\)/] != nil ||
       sample_name[/\//] != nil ||
       sample_name[/\\/] != nil
      errors.add("Sample name must contain only letters, numbers, underscores and dashes or it")
    end
  end
end
