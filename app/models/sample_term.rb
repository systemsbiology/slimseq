class SampleTerm < ActiveRecord::Base
  belongs_to :sample
  belongs_to :naming_term
end