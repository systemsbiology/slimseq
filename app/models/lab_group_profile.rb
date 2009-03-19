class LabGroupProfile < ActiveRecord::Base
  belongs_to :lab_group

  validates_presence_of :lab_group_id
end
