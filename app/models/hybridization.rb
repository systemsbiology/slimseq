class Hybridization < ActiveRecord::Base
  belongs_to :sample

  validates_presence_of :date
  validates_numericality_of :chip_number

  def validate_on_create
    # make sure date/chip number combo is unique
    if Hybridization.find_by_date_and_chip_number(date, chip_number)
      errors.add("Duplicate date/chip number")
    end
  end
end
