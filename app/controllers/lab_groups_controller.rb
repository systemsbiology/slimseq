class LabGroupsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def index
    list
    render :action => 'list'
  end

  def list
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
  end

  def show
    @lab_group = LabGroup.find(params[:id])
  end

  def new
    @lab_group = LabGroup.new
  end

  def create
    @lab_group = LabGroup.new(params[:lab_group])
    if @lab_group.save
      flash[:notice] = 'LabGroup was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @lab_group = LabGroup.find(params[:id])
  end

  def update
    @lab_group = LabGroup.find(params[:id])

    begin
      if @lab_group.update_attributes(params[:lab_group])
        flash[:notice] = 'LabGroup was successfully updated.'
        redirect_to :action => 'list', :id => @lab_group
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this lab group."
      @lab_group = LabGroup.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    begin
      LabGroup.find(params[:id]).destroy
      redirect_to :action => 'list'
    rescue
      flash[:warning] = "Cannot delete lab group due to association " +
                        "with chip transactions or hybridizations."
      list
      render :action => 'list'
    end
  end
end
