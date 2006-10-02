class Organism < ActiveRecord::Base
  has_many :chip_types, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name
end
