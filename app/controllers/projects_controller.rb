class ProjectsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @projects = Project.find(:all, :order => "name ASC")
  end

  def new
    populate_arrays_from_tables
    @project = Project.new
  end

  def create
    populate_arrays_from_tables

    @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    populate_arrays_from_tables
    @project = Project.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    
    @project = Project.find(params[:id])
    
    begin
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        redirect_to :action => 'list', :id => @project
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this project."
      @project = Project.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy    
    Project.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  private
  def populate_arrays_from_tables
    # Administrators and staff can see all projects, otherwise users
    # are restricted to seeing only projects for lab groups they belong to
    if(current_user.staff? || current_user.admin?)
      @lab_groups = LabGroup.find(:all, :order => "name ASC")
    else
      @lab_groups = current_user.lab_groups
    end
  end
end
