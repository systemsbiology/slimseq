class LabMembershipsController < ApplicationController
  before_filter :find_user

  # GET /lab_memberships
  # GET /lab_memberships.xml
  def index
    @lab_memberships = @user.lab_memberships.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_memberships }
    end
  end

  # GET /lab_memberships/new
  # GET /lab_memberships/new.xml
  def new
    @lab_membership = @user.lab_memberships.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab_membership }
    end
  end

  # GET /lab_memberships/1/edit
  def edit
    @lab_membership = @user.lab_memberships.find(params[:id])
  end

  # POST /lab_memberships
  # POST /lab_memberships.xml
  def create
    @lab_membership = @user.lab_memberships.new(params[:lab_membership])

    respond_to do |format|
      if @lab_membership.save
        flash[:notice] = 'LabMembership was successfully created.'
        format.html { redirect_to( user_lab_memberships_path(@user) ) }
        format.xml  { render :xml => @lab_membership, :status => :created, :location => @lab_membership }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lab_membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lab_memberships/1
  # PUT /lab_memberships/1.xml
  def update
    @lab_membership = @user.lab_memberships.find(params[:id])

    respond_to do |format|
      if @lab_membership.update_attributes(params[:lab_membership])
        flash[:notice] = 'LabMembership was successfully updated.'
        format.html { redirect_to( user_lab_memberships_path(@user) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lab_membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_memberships/1
  # DELETE /lab_memberships/1.xml
  def destroy
    @lab_membership = @user.lab_memberships.find(params[:id])
    @lab_membership.destroy

    respond_to do |format|
      format.html { redirect_to( user_lab_memberships_path(@user) ) }
      format.xml  { head :ok }
    end
  end

private

  def find_user
    @user = User.find(params[:user_id])
  end
  
end
