class ElandParameterSet < ActiveRecord::Base
  has_many :samples

  def info
    "#{name} (ELAND Seed Length=#{eland_seed_length}, ELAND Max Matches=#{eland_max_matches})"
  end

end
