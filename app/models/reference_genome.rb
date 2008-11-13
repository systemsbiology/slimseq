class ReferenceGenome < ActiveRecord::Base
  belongs_to :organism

  validates_presence_of :name, :description, :organism_id
end
