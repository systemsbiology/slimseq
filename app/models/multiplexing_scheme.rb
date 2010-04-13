class MultiplexingScheme < ActiveRecord::Base
  has_many :sample_prep_kits

  default_scope :order => "name ASC"
end
