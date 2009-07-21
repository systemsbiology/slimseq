class UserProfile < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id
           
  class << self; attr_accessor :index_columns end
  @index_columns = ['role']

  named_scope :notify_of_new_sequencing_runs,
    :conditions => {:new_sequencing_run_notification => true}

  def before_save
    # make the first user to log in the admin
    if(UserProfile.count == 0)
      self.role = "admin"
    end
  end

  def detail_hash
    return {}
  end
  
  def self.notify_of_new_samples(lab_group)
    new_sample_profiles = UserProfile.find(:all, :conditions => {:new_sample_notification => true})
    lab_group_user_profiles = lab_group.users.collect{|x| x.user_profile}
    lab_group_user_profiles += UserProfile.find(:all, :conditions => "role = 'staff' OR role = 'admin'")
    lab_group_user_profiles.uniq!

    
    return new_sample_profiles & lab_group_user_profiles
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

  def manager?
    role == "manager"
  end
end
