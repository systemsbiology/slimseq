class Sample < ActiveRecord::Base
  has_one :hybridization, :dependent => :destroy

  belongs_to :lab_group
  belongs_to :chip_type
  validates_associated :lab_group, :chip_type
  validates_presence_of :sample_name, :short_sample_name, :date
#  validates_uniqueness_of :sample_name
  validates_length_of :short_sample_name, :maximum => 20
  validates_length_of :sample_name, :maximum => 59
  validates_length_of :sbeams_user, :maximum => 20
  validates_length_of :sbeams_project, :maximum => 50
  validates_length_of :status, :maximum => 50
  
  def validate_on_create
    # make sure date/short_sample_name/sample_name combo is unique
    if Sample.find_by_date_and_short_sample_name_and_sample_name(date, short_sample_name, sample_name)
      errors.add("Duplicate date/short_sample_name/sample_name")
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
       sample_name[/\)/] != nil
      errors.add("Sample name must contain only letters, numbers, underscores and dashes or it")
    end
  end
end
