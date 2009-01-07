=begin rapidoc
name:: /flow_cell_lanes

This resource can be used to list a summary of all flow cell lanes, or show details for 
a particular flow cell lane.
=end

class FlowCellLanesController < ApplicationController
  before_filter :login_required
  
=begin rapidoc
url:: /flow_cell_lanes
method:: GET
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(FlowCellLane.find(:all, :limit => 5).collect{|x| x.summary_hash}) %>
xml:: <%= FlowCellLane.find(:all, :limit => 5).collect{|x| x.summary_hash}.to_xml %>
return:: A list of summary information on all flow cell lanes

Get a list of all flow cell lanes, which doesn't have all the details that are 
available when retrieving single flow cell lanes (see GET /flow_cell_lanes/[flow cell lane id]).
=end  
  
  # GET /flow_cell_lanes
  # GET /flow_cell_lanes.xml
  def index
    @flow_cell_lanes = FlowCellLane.find(:all)

    respond_to do |format|
      format.xml  { render :xml => @flow_cell_lanes
        collect{|x| x.summary_hash}.to_xml
      }
      format.json { render :json => @flow_cell_lanes.
        collect{|x| x.summary_hash}.to_json 
      }
    end
  end

=begin rapidoc
url:: /flow_cell_lanes/[flow cell lane id]
method:: GET
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(FlowCellLane.find(:first).detail_hash) %>
xml:: <%= FlowCellLane.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular flow cell lane

Get detailed information about a single flow cell lane.
=end
  
  # GET /flow_cell_lanes/1
  # GET /flow_cell_lanes/1.xml
  def show
    @flow_cell_lane = FlowCellLane.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @flow_cell_lane.detail_has.to_json }
      format.json  { render :json => @flow_cell_lane.detail_hash.to_json }
    end
  end

#  # GET /flow_cell_lanes/new
#  # GET /flow_cell_lanes/new.xml
#  def new
#    @flow_cell_lane = FlowCellLane.new
#
#    respond_to do |format|
#      format.xml  { render :xml => @flow_cell_lane }
#    end
#  end
#
#  # GET /flow_cell_lanes/1/edit
#  def edit
#    @flow_cell_lane = FlowCellLane.find(params[:id])
#  end
#
#  # POST /flow_cell_lanes
#  # POST /flow_cell_lanes.xml
#  def create
#    @flow_cell_lane = FlowCellLane.new(params[:flow_cell_lane])
#
#    respond_to do |format|
#      if @flow_cell_lane.save
#        flash[:notice] = 'FlowCellLane was successfully created.'
#        format.html { redirect_to(@flow_cell_lane) }
#        format.xml  { render :xml => @flow_cell_lane, :status => :created, :location => @flow_cell_lane }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @flow_cell_lane.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # PUT /flow_cell_lanes/1
#  # PUT /flow_cell_lanes/1.xml
#  def update
#    @flow_cell_lane = FlowCellLane.find(params[:id])
#
#    respond_to do |format|
#      if @flow_cell_lane.update_attributes(params[:flow_cell_lane])
#        flash[:notice] = 'FlowCellLane was successfully updated.'
#        format.html { redirect_to(@flow_cell_lane) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @flow_cell_lane.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # DELETE /flow_cell_lanes/1
#  # DELETE /flow_cell_lanes/1.xml
#  def destroy
#    @flow_cell_lane = FlowCellLane.find(params[:id])
#    @flow_cell_lane.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(flow_cell_lanes_url) }
#      format.xml  { head :ok }
#    end
#  end
end
