class LabMembership < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :user
end
