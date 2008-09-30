class Charge < ActiveRecord::Base
  belongs_to :charge_set

  validates_numericality_of :cost

end
