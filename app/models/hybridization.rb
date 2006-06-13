class Hybridization < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :chip_type
  validates_associated :lab_group, :chip_type
  validates_presence_of :sample_name, :short_sample_name, :date
  validates_length_of :sample_name, :maximum => 59
  validates_numericality_of :chip_number


  def validate_on_create
    # make sure date/chip number combo is unique
    if Hybridization.find_by_date_and_chip_number(date, chip_number)
      errors.add("Can't create due to duplicate date/chip number")
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

# don't need this?
#  def find_by_date_and_chip_number(date, chip_number)
#    Hybridization.find(:first, :conditions => [ "date = ?", date, 
#                       "chip_number = ?", chip_number])
#  end
end
