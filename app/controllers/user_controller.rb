# The UserEngine UserController overrides the UserController from the
# LoginEngine to give user management methods (list, edit_user, etc)
class UserController < ApplicationController

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