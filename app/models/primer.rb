class Primer < ActiveRecord::Base
  belongs_to :platform
  has_many :sample_mixtures

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :not_custom, :conditions => {:custom => false}
  named_scope :custom, :conditions => {:custom => true}
  named_scope :for_platform, lambda {|platform|
    { :conditions => {:platform_id => platform.id} }
  }
end
