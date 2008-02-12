class SampleText < ActiveRecord::Base
  belongs_to :sample
  belongs_to :naming_element
end
