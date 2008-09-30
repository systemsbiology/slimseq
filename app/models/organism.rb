class Organism < ActiveRecord::Base
  has_many :reference_genomes, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name
end
