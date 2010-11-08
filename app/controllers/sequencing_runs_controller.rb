class SequencingRunsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_selections_all, :only => [:edit, :update]
  before_filter :load_dropdown_selections_subset, :only => [:new, :create]

  # GET /sequencing_runs
  # GET /sequencing_runs.xml
  def index
    @sequencing_runs = SequencingRun.find(
      :all,
      :order => "date DESC",
      :include => ['flow_cell','instrument']
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sequencing_runs }
    end
  end

  # GET /sequencing_runs/1
  # GET /sequencing_runs/1.xml
  def show
    @sequencing_run = SequencingRun.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sequencing_run }
    end
  end

  # GET /sequencing_runs/new
  # GET /sequencing_runs/new.xml
  def new
    if(params[:show_all_flow_cells] == "true")
      load_dropdown_selections_all
    end
    
    @sequencing_run = SequencingRun.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sequencing_run }
    end
  end

  # GET /sequencing_runs/1/edit
  def edit
    @sequencing_run = SequencingRun.find(params[:id])
  end

  # POST /sequencing_runs
  # POST /sequencing_runs.xml
  def create
    @sequencing_run = SequencingRun.new(params[:sequencing_run])
    
    respond_to do |format|
      if @sequencing_run.save
        # email notification
        Notifier.deliver_sequencing_run_notification(@sequencing_run)
        
        flash[:notice] = 'SequencingRun was successfully created.'
        format.html { redirect_to(sequencing_runs_url) }
        format.xml  { render :xml => @sequencing_run, :status => :created, :location => @sequencing_run }
      else
        # only show active instruments when re-rendering 'new'
        @instruments = Instrument.active.find(:all, :order => "name ASC")
        
        format.html { render :action => "new" }
        format.xml  { render :xml => @sequencing_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sequencing_runs/1
  # PUT /sequencing_runs/1.xml
  def update
    @sequencing_run = SequencingRun.find(params[:id])

    respond_to do |format|
      if @sequencing_run.update_attributes(params[:sequencing_run])
        flash[:notice] = 'SequencingRun was successfully updated.'
        format.html { redirect_to(sequencing_runs_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sequencing_run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sequencing_runs/1
  # DELETE /sequencing_runs/1.xml
  def destroy
    @sequencing_run = SequencingRun.find(params[:id])

    if(@sequencing_run.pipeline_results.size == 0)
      @sequencing_run.destroy
    else
      flash[:warning] = "Unable to destroy sequencing runs that have gone through the pipeline."
    end

    respond_to do |format|
      format.html { redirect_to(sequencing_runs_url) }
      format.xml  { head :ok }
    end
  end

  def default_output_paths
    @sequencing_run = SequencingRun.find(params[:id])
  end

private

  def load_dropdown_selections_all
    @platform = Platform.find_by_id(params[:platform_id])
    @flow_cells = FlowCell.find(:all, :order => "name ASC")
    @instruments = Instrument.find(:all, :order => "name ASC")

    mixtures = @platform ? @platform.sample_mixtures : SampleMixture
    @sample_mixtures = mixtures.find_all_by_control(true, :order => "name_on_tube ASC")
    @sample_mixtures += mixtures.find_all_by_control(false, :order => "name_on_tube ASC")
  end
  
  def load_dropdown_selections_subset
    @platform = Platform.find(params[:platform_id])
    @flow_cells = FlowCell.find_all_by_status('clustered', :order => "name ASC")
    @instruments = @platform.instruments.active.find(:all, :order => "name ASC")

    mixtures = @platform ? @platform.sample_mixtures : SampleMixture
    @sample_mixtures = mixtures.find_all_by_control(true, :order => "name_on_tube ASC")
    @sample_mixtures += mixtures.find_all_by_control_and_status_and_ready_for_sequencing(false, 'submitted',
      true, :order => "name_on_tube ASC")
  end
end
