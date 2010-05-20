class MultiplexingScheme < ActiveRecord::Base
  has_many :sample_prep_kits
  has_many :multiplex_codes

  default_scope :order => "name ASC"
end
