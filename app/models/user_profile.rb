class UserProfile < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id
           
  class << self; attr_accessor :index_columns end
  @index_columns = ['role']

  ####################################################
  # Authorization
  ####################################################
  def staff_or_admin?
    role == "staff" || role == "admin"
  end
 
  def admin?
    role == "admin"
  end
end
