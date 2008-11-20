class Instrument < ActiveRecord::Base
  named_scope :active, :conditions => {:active => true}

  def name_with_version
    return "#{name} (#{instrument_version})"
  end
end
