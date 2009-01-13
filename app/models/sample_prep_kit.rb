class SamplePrepKit < ActiveRecord::Base
  has_many :samples

  def detail_hash
    return {
      :id => id,
      :name => name,
      :restriction_enzyme => restriction_enzyme,
      :updated_at => updated_at
    }
  end
end
