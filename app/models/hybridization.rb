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
  
  def self.populate_all_raw_data_paths
    hybridizations = Hybridization.find(:all)
    
    populate_raw_data_paths(hybridizations)
  end

  def self.populate_raw_data_paths(hybridizations)
    raw_data_root_path = SiteConfig.raw_data_root_path
 
    for hybridization in hybridizations
      sample = hybridization.sample
      # only do this for affy samples
      if( sample.chip_type.array_platform == "affy")
        hybridization_year_month = hybridization.hybridization_date.year.to_s + 
                                   ("%02d" % hybridization.hybridization_date.month)
        hybridization_date_number_string = hybridization_year_month +
                             ("%02d" % hybridization.hybridization_date.day) + "_" + 
                             ("%02d" % hybridization.chip_number)
        hybridization.raw_data_path = raw_data_root_path + "/" + hybridization_year_month + "/" +
                                      hybridization_date_number_string + "_" + 
                                      sample.sample_name + ".CEL"
        hybridization.save
      end
    end
  end
end
