=begin rapidoc
name:: /users

This resource can be used to list a summary of all users, or show details for
a particular user.<br><br>

A user can have and belong to many lab groups.
=end

class UsersController < ApplicationController
  before_filter :login_required, :only => [ :index, :show, :edit, :update, :destroy ]
  before_filter :staff_or_admin_required, :only => [ :index, :show, :edit, :update, :destroy ]
  
  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      self.current_user = @user
      redirect_back_or_default(SiteConfig.site_url)
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end

=begin rapidoc
url:: /users
method:: GET
example:: <%= SiteConfig.site_url %>/users
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(User.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= User.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of all summary information on all users

Get a list of all users, which doesn't have all the details that are
available when retrieving single users (see GET /users/[user id]).
=end

  # GET /users
  # GET /users.xml
  # GET /users.json
  def index
    @users = User.find(:all, :order => "lastname ASC")

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @users.
        collect{|x| x.summary_hash}
      }
      format.json { render :json => @users.
        collect{|x| x.summary_hash}.to_json
      }
    end
  end

=begin rapidoc
url:: /users/[user id]
method:: GET
example:: <%= SiteConfig.site_url %>/users/5.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(User.find(:first).detail_hash) %>
xml:: <%= User.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular user

Get detailed information about a single user.
=end

  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @user.detail_hash }
      format.json  { render :json => @user.detail_hash }
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(users_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
end
