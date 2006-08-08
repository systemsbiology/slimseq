class Hybridization < ActiveRecord::Base
  belongs_to :sample

  validates_presence_of :hybridization_date
  validates_numericality_of :chip_number

  def validate_on_create
    # make sure date/chip number combo is unique
    if Hybridization.find_by_hybridization_date_and_chip_number(hybridization_date, chip_number)
      errors.add("Duplicate hybridization hybridization date/chip number")
    end
  end
end
