class Organism < ActiveRecord::Base
  has_many :chip_types, :dependent => :destroy
end
