class StudiesController < ApplicationController
  before_filter :login_required

  # GET /studies
  # GET /studies.xml
  def index
    @studies = Study.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @studies }
    end
  end

  # GET /studies/1
  # GET /studies/1.xml
  def show
    @study = Study.find(params[:id])
    @project=Project.find(@study.project_id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @study }
    end
  end

  # GET /studies/new
  # GET /studies/new.xml
  def new
    @study = Study.new
    @projects=Project.find(:all) # fixme: only want projects accessible to user

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @study }
    end
  end

  # GET /studies/1/edit
  def edit
    @study = Study.find(params[:id])
    @projects=Project.find(:all)
    @experiments=Experiment.all(:conditions=>{:study_id=>@study.id})
  end

  # POST /studies
  # POST /studies.xml
  def create
    @study=Study.new(params[:study])
    study_params=params[:study]
    project_id=study_params[:project_id].to_i
    raise "no :project_id???" unless project_id>0
    @project=Project.find(project_id)

    respond_to do |format|
      if @study.save
        flash[:notice] = 'Study was successfully created.'
        format.html { redirect_to(edit_project_path(@project)) } # fixme: this is going to barf
        format.xml  { render :xml => @study, :status => :created, :location => @study }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @study.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /studies/1
  # PUT /studies/1.xml
  def update
    @study = Study.find(params[:id])

    respond_to do |format|
      if @study.update_attributes(params[:study])
        flash[:notice] = 'Study was successfully updated.'
        format.html { redirect_to(@study) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @study.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /studies/1
  # DELETE /studies/1.xml
  def destroy
    @study = Study.find(params[:id])
    @study.destroy

    respond_to do |format|
      format.html { redirect_to(studies_url) }
      format.xml  { head :ok }
    end
  end
end
