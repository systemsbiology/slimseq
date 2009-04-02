class GeraldDefaultsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  def update
    @gerald_defaults = GeraldDefaults.find(params[:id])
    @sequencing_run = SequencingRun.find(params[:sequencing_run_id])
    @flow_cell_lanes = @sequencing_run.flow_cell.flow_cell_lanes

    respond_to do |format|
      if @gerald_defaults.update_attributes(params[:gerald_defaults])
        flash[:notice] = 'Gerald defaults were successfully updated.'
        format.html { redirect_to(new_sequencing_run_gerald_configuration_path(@sequencing_run)) }
        #format.xml  { head :ok }
        #format.json  { head :ok }
      else
        format.html { render :template => "gerald_configurations/new" }
        #format.xml  { render :xml => @gerald_defaults.errors, :status => :unprocessable_entity }
        #format.json  { render :json => @gerald_defaults.errors, :status => :unprocessable_entity }
      end
    end
  end

end
