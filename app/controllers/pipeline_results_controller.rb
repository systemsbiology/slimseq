class PipelineResultsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  # GET /pipeline_results
  def index
    @pipeline_results = PipelineResult.find(
      :all,
      :order => "gerald_date DESC, flow_cell_lanes.lane_number ASC",
      :include => :flow_cell_lane
    )
  end

  # GET /pipeline_results/1/edit
  def edit
    @pipeline_result = PipelineResult.find(params[:id])
  end

  # PUT /pipeline_results/1
  # PUT /pipeline_results/1.xml
  def update
    @pipeline_result = PipelineResult.find(params[:id])

    respond_to do |format|
      if @pipeline_result.update_attributes(params[:pipeline_result])
        flash[:notice] = 'Pipeline result was successfully updated.'
        format.html { redirect_to(pipeline_results_url) }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pipeline_result.errors, :status => :unprocessable_entity }
        format.json  { render :json => @pipeline_result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pipeline_results/1
  # DELETE /pipeline_results/1.xml
  def destroy
    @pipeline_result = PipelineResult.find(params[:id])
    @pipeline_result.destroy

    respond_to do |format|
      format.html { redirect_to(pipeline_results_url) }
      format.xml  { head :ok }
    end
  end
end
