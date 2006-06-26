class Organism < ActiveRecord::Base
  has_many :chip_types, :dependent => :destroy

  validates_uniqueness_of :name
end
