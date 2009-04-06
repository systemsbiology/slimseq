class UserProfile < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id
           
  class << self; attr_accessor :index_columns end
  @index_columns = ['role']

  named_scope :notify_of_new_samples,
    :conditions => {:new_sample_notification => true}
  named_scope :notify_of_new_sequencing_runs,
    :conditions => {:new_sequencing_run_notification => true}

  def detail_hash
    return {}
  end

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
