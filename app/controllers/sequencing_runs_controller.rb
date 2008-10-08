class SequencingRunsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections

  # GET /sequencing_runs
  # GET /sequencing_runs.xml
  def index
    @sequencing_runs = SequencingRun.find(:all)

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
        flash[:notice] = 'SequencingRun was successfully created.'
        format.html { redirect_to(sequencing_runs_url) }
        format.xml  { render :xml => @sequencing_run, :status => :created, :location => @sequencing_run }
      else
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
        format.html { redirect_to(@sequencing_run) }
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
    @sequencing_run.destroy

    respond_to do |format|
      format.html { redirect_to(sequencing_runs_url) }
      format.xml  { head :ok }
    end
  end

private

  def load_dropdown_selections
    @flow_cells = FlowCell.find_all_by_status('clustered', :order => "name ASC")
    @instruments = Instrument.find(:all, :order => "name ASC")
  end
end