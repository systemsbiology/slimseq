#class WelcomeController < ApplicationController::Base
class WelcomeController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required, :only => [ :staff ]
  
  def index
    if(current_user.staff_or_admin?)
      redirect_to :action => 'staff'
    else
      redirect_to :action => 'home'
    end
  end

  def home
    # Admins get their own home page
    if(current_user != :false && current_user.staff_or_admin?)
      redirect_to :action => 'staff'
    else 
      # Make an array of the accessible lab group ids, and use this
      # to find the current user's accessible samples in a nice sorted list
      lab_group_ids = current_user.get_lab_group_ids
      if(lab_group_ids != nil && lab_group_ids.size > 0)
        @sample_mixtures = SampleMixture.find(:all, 
           :include => 'project',
           :conditions => [ "status != ? AND projects.lab_group_id IN (?) AND control = ?",
            'completed', lab_group_ids, false ],
           :order => "sample_mixtures.id ASC")
        @completed_sample_mixtures = SampleMixture.find(:all, 
           :include => 'project',
           :conditions => [ "status = ? AND projects.lab_group_id IN (?) AND control = ?",
            'completed', lab_group_ids, false ],
           :order => "sample_mixtures.submission_date DESC",
           :limit => 10)
        @users_by_id = User.all_by_id
      end
    end
  end

  def staff
    # Make an array of the accessible lab group ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @sample_mixtures = SampleMixture.find(:all, :conditions => [ "status = ? AND control = ?", 'submitted', false],
                              :order => "sample_mixtures.id ASC")
    @users_by_id = User.all_by_id
    @flow_cells = FlowCell.find(:all, :conditions => "status = 'clustered'")
  end

end
