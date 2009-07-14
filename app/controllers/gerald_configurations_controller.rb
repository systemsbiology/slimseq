class GeraldConfigurationsController < ApplicationController
  before_filter :get_sequencing_run
  
  def new
    @flow_cell_lanes = @sequencing_run.flow_cell.flow_cell_lanes
    @gerald_defaults = GeraldDefaults.find(:first)
  end

  def create
    @lanes = params[:lanes]
    
    @sequencing_run.write_config_file(@lanes)
    @gerald_defaults = GeraldDefaults.find(:first)
  end
  
  def download
    send_file "tmp/txt/#{@sequencing_run.run_name}-config.txt", :type => 'text/plain'
  end

  def default
    if(@sequencing_run)
      lane_params = @sequencing_run.default_gerald_params
      @sequencing_run.write_config_file(lane_params)
      
      render :file => "tmp/txt/#{@sequencing_run.run_name}-config.txt"
    else
      render :file => "app/views/gerald_configurations/no_sequencing_run.txt"
    end
  end
  
private
  
  def get_sequencing_run
    # search by id if available
    if(params[:sequencing_run_id] != nil)
      @sequencing_run = SequencingRun.find(params[:sequencing_run_id])
    # otherwise search by name if available
    elsif(params[:sequencing_run_name] != nil)
      @sequencing_run = SequencingRun.find_by_run_name(params[:sequencing_run_name])
    end    
  end
end
