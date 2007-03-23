class NamingScheme < ActiveRecord::Base
  has_many :naming_elements, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name
end