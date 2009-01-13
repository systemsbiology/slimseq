class Instrument < ActiveRecord::Base
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
