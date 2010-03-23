class PipelineRunsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  # POST /pipeline_runs.xml
  # POST /pipeline_runs.json
  def create
    @pipeline_run = PipelineRun.new(
      :base_directory => params[:run_folder],
      :summary_files => params[:summary_files],
      :eland_output_files => params[:eland_output_files]
    )
    
    respond_to do |format|
      if(@pipeline_run.valid?)
        @pipeline_run.pipeline_results.each do |result|
          result.save
        end
        
        format.xml  {
          render :xml => "Pipeline run(s) recorded", :status => :created,
          :location => @pipeline_result
        }
      else
        format.xml  {
          render :xml => @pipeline_run.errors.full_messages.join(", "),
            :status => :unprocessable_entity 
        }
      end
    end    
  end

end
