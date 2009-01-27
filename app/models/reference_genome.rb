class ReferenceGenome < ActiveRecord::Base
  belongs_to :organism
  has_many :samples

  validates_presence_of :name, :description, :organism_id
end
