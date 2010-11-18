class SamplePrepKit < ActiveRecord::Base
  belongs_to :platform
  has_many :samples

  belongs_to :multiplexing_scheme

  validates_presence_of :platform_id

  named_scope :not_custom, :conditions => {:custom => false}
  named_scope :custom, :conditions => {:custom => true}
  named_scope :for_platform, lambda {|platform|
    { :conditions => {:platform_id => platform.id} }
  }

  def detail_hash
    return {
      :id => id,
      :name => name,
      :restriction_enzyme => restriction_enzyme,
      :paired_end => paired_end ? "Yes" : "No",
      :updated_at => updated_at
    }
  end

  def eland_analysis
    paired_end ? "eland_pair" : "eland_extended"
  end
end
