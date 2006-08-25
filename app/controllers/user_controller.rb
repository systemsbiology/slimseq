# The UserEngine UserController overrides the UserController from the
# LoginEngine to give user management methods (list, edit_user, etc)
class UserController < ApplicationController

  def home
    # Admins get their own home page
    if(current_user.staff? || current_user.admin?)
      redirect_to :action => 'staff'
    end
    
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
    
    # Make an array of the accessible lab group ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    @lab_groups = current_user.lab_groups
    @chip_types = ChipType.find(:all, :order => "name ASC")
    if(@lab_groups != nil && @lab_groups.size > 0)
      lab_group_ids = Array.new
      for lab_group in @lab_groups
        lab_group_ids << lab_group.id
      end
      @samples = Sample.find(:all, :conditions => [ "lab_group_id IN (?) AND status = ?", lab_group_ids, 'submitted' ],
                                :order => "submission_date DESC, sample_name ASC")
    end
  end

  def staff
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
    
    # Make an array of the accessible lab group ids, and use this
    # to find the current user's accessible samples in a nice sorted list
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @samples = Sample.find(:all, :conditions => [ "status = ?", 'submitted' ],
                              :order => "submission_date DESC, sample_name ASC")
  end

  # Edit the details of any user. The Role which can perform this will almost certainly also
  # need the following permissions: user/change_password, user/edit, user/edit_roles, user/delete
  def edit_user
    if (@user = find_user(params[:id]))
      @all_roles = Role.find_all.select { |r| r.name != UserEngine.config(:guest_role_name) }
      @all_lab_groups = LabGroup.find(:all, :order => "name ASC")
      case request.method
        when :get
        when :post
          @user.attributes = params[:user].delete_if { |k,v| not LoginEngine.config(:changeable_fields).include?(k) }
          if @user.save
            flash.now[:notice] = "Details for user '#{@user.login}' have been updated"
          else
            flash.now[:warning] = "Details could not be updated!"
          end
      end
    else
      redirect_back_or_default :action => 'list'
    end
  end
  
  # Edit the lab groups for a given user.
  # A user typically shouldn't be allowed to edit their own lab gropus, since they could
  # assign themselves as Admins and then do anything. Therefore, keep this method
  # locked down as much as possible.
  def edit_lab_groups
    if (@user = find_user(params[:id]))
      begin
        User.transaction(@user) do
          if(params[:user] != nil)
            lab_groups = params[:user][:lab_groups].collect { |lab_group_id| LabGroup.find(lab_group_id) }          
          else
            lab_groups = Array.new
          end

          for lab_group in lab_groups
            if !@user.lab_groups.include?(lab_group)
              LabMembership.create(:lab_group => lab_group, :user => @user)  
            end
          end

          for lab_group in @user.lab_groups
            if !lab_groups.include?(lab_group)
              LabMembership.find( :first, :conditions => ["user_id = ? AND lab_group_id = ?",
                                                          @user.id, lab_group.id] ).destroy
            end
          end
          flash[:notice] = "Lab groups updated for user '#{@user.login}'."
        end
      rescue
        flash[:warning] = 'Lab groups could not be edited at this time. Please retry.'
      ensure
        redirect_to :back
      end
    else
      redirect_back_or_default :action => 'list'
    end
  end
  
  # Display the details for a given user
  def show    
    if (@user = find_user(params[:id]))
      @content_columns = user_content_columns_to_display
    else
      redirect_back_or_default :action => 'list'
    end
  end

end