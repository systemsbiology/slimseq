class LabMembership < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :user

  validates_associated :lab_group
  validates_associated :user
  
  validate :unique_combination_of_lab_group_and_user
  
private

  def unique_combination_of_lab_group_and_user
    duplicate_memberships = LabMembership.find(:all,
          :conditions => ["user_id =? AND lab_group_id = ? AND id NOT IN (?)",
          user_id, lab_group_id, id])
    
    if( duplicate_memberships.size > 0 )
      errors.add("non-unique combination of user and lab group")
    end
  end
end
