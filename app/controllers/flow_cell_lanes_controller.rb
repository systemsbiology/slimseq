class FlowCellLanesController < ApplicationController
  # GET /flow_cell_lanes
  # GET /flow_cell_lanes.xml
  def index
    @flow_cell_lanes = FlowCellLane.find(:all)

    respond_to do |format|
      format.xml  { render :xml => @flow_cell_lanes }
      format.json { render :json => @flow_cell_lanes.to_json(
        :except => [:lock_version, :flow_cell_id],
        :include => {
          :flow_cell => {
            :except => :id,
            :include => {
              :sequencing_run => {
                :except => :instrument_id,
                :include => {
                  :instrument => {
                    :only => [:name, :serial_number]
                  }
                }
              }
            }
          }
        }
      ) }
    end
  end

  # GET /flow_cell_lanes/1
  # GET /flow_cell_lanes/1.xml
  def show
    @flow_cell_lane = FlowCellLane.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @flow_cell_lane }
      format.json { render :json => @flow_cell_lane.to_json(
          :include => {
            :samples => {
              :include => [:sample_terms, :sample_texts]
            }
          }
        ) }
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
