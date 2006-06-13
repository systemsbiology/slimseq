class InventoryCheck < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :chip_type
  
  validates_numericality_of :number_expected
  validates_numericality_of :number_counted
end
