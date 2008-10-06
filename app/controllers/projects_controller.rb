class ProjectsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_selections, :only => [:new, :create, :edit, :update]
  
  def index
    list
    render :action => 'list'
  end

  def list
    @projects = Project.find(:all, :order => "name ASC")
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
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
  
  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
  end
end