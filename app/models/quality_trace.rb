class QualityTrace < ActiveRecord::Base
  belongs_to :bioanalyzer_run
  validates_associated :bioanalyzer_run

  belongs_to :lab_group
  validates_associated :lab_group

  has_one :sample
end
