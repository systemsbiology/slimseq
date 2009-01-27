class Instrument < ActiveRecord::Base
  has_many :sequencing_runs

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
