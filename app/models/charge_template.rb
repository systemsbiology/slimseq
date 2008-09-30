class ChargeTemplate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  validates_numericality_of :cost
end
