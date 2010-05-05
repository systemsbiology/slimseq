require 'numeric_helpers'

class PostPipelinesController < ApplicationController
  before_filter :pp_before_filter
  def pp_before_filter
    # add our settings to AppConfig
    AppConfig.load("vendor/plugins/post_pipelines/config/application.yml",'common')
  end


  # GET /post_pipelines
  # GET /post_pipelines.xml
  def index
    @post_pipelines = PostPipeline.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @post_pipelines }
    end
  end

  # GET /post_pipelines/1
  # GET /post_pipelines/1.xml
  def show
    @post_pipeline = PostPipeline.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post_pipeline }
    end
  end

  # GET /post_pipelines/new
  # GET /post_pipelines/new.xml
  def new
    @post_pipeline = PostPipeline.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post_pipeline }
    end
  end

  # GET /post_pipelines/1/edit
  def edit
    @post_pipeline = PostPipeline.find(params[:id])
  end

  # POST /post_pipelines
  # POST /post_pipelines.xml
  def create
    logger.info "debug: I'm a baby dwagon!";
    @post_pipeline = PostPipeline.new(params[:post_pipeline])

    respond_to do |format|
      if @post_pipeline.save
        flash[:notice] = 'PostPipeline was successfully created.'
        format.html { redirect_to(@post_pipeline) }
        format.xml  { render :xml => @post_pipeline, :status => :created, :location => @post_pipeline }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @post_pipeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /post_pipelines/1
  # PUT /post_pipelines/1.xml
  def update
    @post_pipeline = PostPipeline.find(params[:id])
    logger.info "params are #{params.inspect}"

    respond_to do |format|
      if @post_pipeline.update_attributes(params[:post_pipeline])
        flash[:notice] = 'PostPipeline was successfully updated.'
        format.html { redirect_to(@post_pipeline) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @post_pipeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /post_pipelines/1
  # DELETE /post_pipelines/1.xml
  def destroy
    @post_pipeline = PostPipeline.find(params[:id])
    @post_pipeline.destroy

    respond_to do |format|
      format.html { redirect_to(post_pipelines_url) }
      format.xml  { head :ok }
    end
  end


  ########################################################################
  # create and save post_pipeline objects for each fcl related to the sample
  # 
  def make_pipelines(sample)
    sample=Sample.find params[:sample_id] if sample.nil?
    fcls=sample.flow_cell_lanes;
    n_pipelines=0

    if (fcls.count == 0)
      @msgs << "No flow cell lane for '#{sample.name_on_tube}'"
      return 0
    end
    fcls.each do |fcl|

      # create pipeline object:
      pp=PostPipeline.new(params[:post_pipeline])
      pp.status='Created'
      pp.get_sample_params!(sample) # could possibly incorporate these into constructor...?
      pp.current_user=current_user

      # gather more params:
      begin
        pp.get_pipeline_result_params!(fcl)
        pp.name=pp.label
      rescue RuntimeError => barf
        if /no pipeline_result/.match barf
          @msgs << "No (eland) pipeline for #{sample.name_on_tube}"

        elsif /export_file missing/.match barf
          @msgs << "No export file(s) found for #{sample.name_on_tube}"

        else 
          @msgs << "Error: #{barf.message}" # otherwise the page completely breaks

        end
        next
      end
      pp.save

      # launch!
      begin
        raise "job for this sample already running" if pp.already_running
        pp.launch               # launch the pipeline
        n_pipelines+=1          # why doesn't n_pipelines++ work??? stoopid ruby
      rescue Exception => barf
        @msgs << barf
        pp.status="Failed: #{barf.message}"
        pp.save
      end
    end
    n_pipelines
  end

  ########################################################################
  # launch multiple pipelines (or one); 
  # will replace launch_sample and launch_exp
  # redirected from samples/bulk_handler (as displayed by views/samples/list.html.erb
  # params[] contains sample_ids

  def launch_multi
    # have to make sure all the samples are compatible (same real_read_length, etc)
    # Can't use _post_pipeline_params as is because of sample.real_read_length
    @msgs=Array.new
#    begin
      @email=current_user.email

      # find sample and verify objects:
      @samples = params[:selected_samples].map { |sample_id| Sample.find sample_id }

      begin
        Sample.rnaseq_compatible?(@samples)
      rescue RuntimeError => e
        @disable_launch=true
        @why_disabled="Incompatible samples"
        @msgs<<"Incompatible samples"
      end

      n_pipelines=0
      if @msgs.length == 0 
        @samples.each do |sample|
          n_pipelines+=make_pipelines(sample)
        end
      end
      
      @msgs << "#{n_pipelines} pipelines launched"
      flash[:notice]=@msgs.join("<br />\n")
      #    redirect_to :controller=>:samples, :action=>:pipeline, :id=>sample.id
#    rescue Exception => e
#      logger.warn "INTERNAL ERROR: #{e.message}"
#      render :template=> "post_pipelines/error", :collection=> e.message
#    end
  end



  ########################################################################
  # called by views/samples/pipeline.html.erb
  # also called from launch_exp
  def launch_sample
    sample=Sample.find(params[:sample_id])
    raise "no sample w/id=#{params[:sample_id]}" if sample.nil?
    @msgs=[]
    n_pipelines=make_pipelines(sample) # also launches
    
    @msgs << "#{n_pipelines} pipelines launched"
    flash[:notice]=@msgs.join('<br />')
    redirect_to :controller=>:samples, :action=>:pipeline, :id=>sample.id
  end

  ########################################################################
  def launch_exp                # called by views/experiments/pipeline.html.erb
    # create a pipeline object for each flow_cell_lane object of sample
    sample_ids=params[:include_sample]
    exp=Experiment.find(params[:experiment_id])
    n_pipelines=0
    @msgs=[]
    sample_ids.each do |sid| 
      sample=Sample.find(sid)
      n_pipelines+=make_pipelines(sample) # also launches
    end
    @msgs << "#{n_pipelines} pipelines launched"
    flash[:notice]=@msgs.join('<br />')

    
    redirect_to :controller=>:experiments, :action=>:pipeline, :id=>exp.id
  end

  ########################################################################
  def help
    # easy peasy
  end
  
end
