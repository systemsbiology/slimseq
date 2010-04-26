=begin rapidoc
name:: /flow_cells

This resource can be used to list a summary of all flow cells, or show details for 
a particular flow cell.<br><br>

A flow cell has multiple (right now it is always 8) flow cell lanes, each of 
which is associated with a sample. A flow cell is associated with a sequencer, 
if it has been sequenced.
=end

class FlowCellsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections_only_submitted, :only => [:new, :create]
  before_filter :load_dropdown_selections_all, :only => [:edit, :update]

=begin rapidoc
url:: /flow_cells
method:: GET
example:: <%= SiteConfig.site_url %>/flow_cells
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(FlowCell.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= FlowCell.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of summary information on all flow cells

Get a list of all flow cells, which doesn't have all the details that are 
available when retrieving single flow cells (see GET /flow_cells/[flow cell id]).
=end  
    
  # GET /flow_cells
  # GET /flow_cells.xml
  def index
    @flow_cells = FlowCell.find(:all, :order => "date_generated DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @flow_cells.
        collect{|x| x.summary_hash}
      }
      format.json  { render :json => @flow_cells.
        collect{|x| x.summary_hash}.to_json
      }
    end
  end

=begin rapidoc
url:: /flow_cells/[flow cell id]
method:: GET
example:: <%= SiteConfig.site_url %>/flow_cells/10.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(FlowCell.find(:first).detail_hash) %>
xml:: <%= FlowCell.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular flow cell

Get detailed information about a single flow cell.
=end
  
  # GET /flow_cells/1
  # GET /flow_cells/1.xml
  def show
    @flow_cell = FlowCell.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @flow_cell.detail_hash }
      format.json  { render :json => @flow_cell.detail_hash }
    end
  end

  # GET /flow_cells/new
  # GET /flow_cells/new.xml
  def new
    if(params[:show_all_samples] == "true")
      load_dropdown_selections_all
    end
    
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

    if(@flow_cell.status == "clustered")
      @flow_cell.destroy
    else
      flash[:warning] = "Unable to destroy flow cells that have been sequenced."
    end

    respond_to do |format|
      format.html { redirect_to(flow_cells_url) }
      format.xml  { head :ok }
    end
  end
  
private

  def load_dropdown_selections_only_submitted
    @sample_mixtures = SampleMixture.find_all_by_control(true, :order => "name_on_tube ASC")
    @sample_mixtures += SampleMixture.find_all_by_control_and_status_and_ready_for_sequencing(false, 'submitted',
      true, :order => "name_on_tube ASC")
  end
  
  def load_dropdown_selections_all
    @sample_mixtures = SampleMixture.find_all_by_control(true, :order => "name_on_tube ASC")
    @sample_mixtures += SampleMixture.find_all_by_control(false, :order => "name_on_tube ASC")
  end
end
