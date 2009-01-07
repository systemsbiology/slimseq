=begin rapidoc
name:: /projects

This resource can be used to list a summary of all projects, or show details for 
a particular project.
=end

class ProjectsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_selections, :only => [:new, :new_inline, :create, :create_inline,
                                                     :edit, :update]

=begin rapidoc
url:: /projects
method:: GET
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Project.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= Project.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of all summary information on all projects

Get a list of all projects, which doesn't have all the details that are 
available when retrieving single projects (see GET /projects/[project id]).
=end
  
  def index
    @projects = Project.find(:all, :order => "name ASC")
    
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @projects }
      format.json { render :json => @projects.
        collect{|x| x.summary_hash}.to_json
      }
    end
  end

=begin rapidoc
url:: /projects/[project id]
method:: GET
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(Project.find(:first).detail_hash) %>
xml:: <%= Project.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular project

Get detailed information about a single project.
=end
  
  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @project }
      format.json  { render :json => @project.detail_hash }
    end
  end
  
  def new
    @project = Project.new
  end

  def new_inline
    @project = Project.new
    render :partial => 'new_inline'
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

  def create_inline
    @project = Project.new(params[:project])
    if @project.save
      @projects = current_user.accessible_projects
      @sample_set = SampleSet.new(:project_id => @project.id)
      render :partial => 'sample_sets/projects'
    else
      render :partial => 'new_inline'
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