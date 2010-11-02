class Instrument < ActiveRecord::Base
  belongs_to :platform
  has_many :sequencing_runs
  
  validates_presence_of :platform

  named_scope :active, :conditions => {:active => true}

  def name_with_version
    return "#{name} (#{instrument_version})"
  end

  def detail_hash
    return {
      :id => id,
      :name => name,
      :serial_number => serial_number,
      :instrument_version => instrument_version,
      :updated_at => updated_at
    }
  end
end
