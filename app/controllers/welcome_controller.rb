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
    if(current_user.staff_or_admin?)
      redirect_to :action => 'staff'
    end
    
    # get all possible naming schemes
    @naming_schemes = NamingScheme.find(:all)

    # Make an array of the accessible lab group ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    @lab_groups = current_user.lab_groups
    if(@lab_groups != nil && @lab_groups.size > 0)
      lab_group_ids = Array.new
      for lab_group in @lab_groups
        lab_group_ids << lab_group.id
      end

      @samples = Sample.find(:all, 
         :include => 'project',
         :conditions => [ "status = ? AND projects.lab_group_id IN (?) AND control = ?",
          'submitted', current_user.get_lab_group_ids, false ],
         :order => "samples.id ASC")
      @users_by_id = User.all_by_id
    end
  end

  def staff
    # get all possible naming schemes
    @naming_schemes = NamingScheme.find(:all)

    # Make an array of the accessible lab group ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @samples = Sample.find(:all, :conditions => [ "status = ? AND control = ?", 'submitted', false],
                              :order => "samples.id ASC")
    @users_by_id = User.all_by_id
    @flow_cells = FlowCell.find(:all, :conditions => "status = 'clustered'")
  end

end
