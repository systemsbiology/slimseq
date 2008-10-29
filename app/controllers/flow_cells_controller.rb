class FlowCellsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections_only_submitted, :only => [:new, :create]
  before_filter :load_dropdown_selections_all, :only => [:edit, :update]
  
  # GET /flow_cells
  # GET /flow_cells.xml
  def index
    @flow_cells = FlowCell.find(:all, :order => "date_generated DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @flow_cells }
    end
  end

  # GET /flow_cells/1
  # GET /flow_cells/1.xml
  def show
    @flow_cell = FlowCell.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @flow_cell }
    end
  end

  # GET /flow_cells/new
  # GET /flow_cells/new.xml
  def new
    @flow_cell = FlowCell.new
    (1..8).to_a.each{ |n| @flow_cell.flow_cell_lanes.build(:lane_number => n) }

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @flow_cell }
    end
  end

  # GET /flow_cells/1/edit
  def edit
    @flow_cell = FlowCell.find(params[:id])
  end

  # POST /flow_cells
  # POST /flow_cells.xml
  def create
    @flow_cell = FlowCell.new(params[:flow_cell])

    respond_to do |format|
      if @flow_cell.save
        flash[:notice] = 'FlowCell was successfully created.'
        format.html { redirect_to(@flow_cell) }
        format.xml  { render :xml => @flow_cell, :status => :created, :location => @flow_cell }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @flow_cell.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /flow_cells/1
  # PUT /flow_cells/1.xml
  def update
    @flow_cell = FlowCell.find(params[:id])

    respond_to do |format|
      if @flow_cell.update_attributes(params[:flow_cell])
        flash[:notice] = 'FlowCell was successfully updated.'
        format.html { redirect_to(@flow_cell) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @flow_cell.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /flow_cells/1
  # DELETE /flow_cells/1.xml
  def destroy
    @flow_cell = FlowCell.find(params[:id])
    @flow_cell.destroy

    respond_to do |format|
      format.html { redirect_to(flow_cells_url) }
      format.xml  { head :ok }
    end
  end
  
private

  def load_dropdown_selections_only_submitted
    @samples = Sample.find_all_by_control(true, :order => "short_sample_name ASC")
    @samples += Sample.find_all_by_control_and_status(false, 'submitted',
      :order => "short_sample_name ASC")
  end
  
  def load_dropdown_selections_all
    @samples = Sample.find_all_by_control(true, :order => "short_sample_name ASC")
    @samples += Sample.find_all_by_control(false, :order => "short_sample_name ASC")
  end
end
