class ExperimentsController < ApplicationController
  # GET /experiments
  # GET /experiments.xml
  def index
    @experiments = Experiment.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @experiments }
    end
  end

  # GET /experiments/1
  # GET /experiments/1.xml
  def show
    @experiment = Experiment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @experiment }
    end
  end

  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = Experiment.new
    @studies=Study.find(:all)   # fixme: only studies available to user

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @experiment }
    end
  end

  # GET /experiments/1/edit
  def edit
    @experiment = Experiment.find(params[:id])
    @studies=Study.all
    @samples=Sample.all(:conditions => {:experiment_id=>@experiment.id})
  end

  # POST /experiments
  # POST /experiments.xml
  def create
    @experiment = Experiment.new(params[:experiment])

    respond_to do |format|
      if @experiment.save
        flash[:notice] = 'Experiment was successfully created.'
        format.html { redirect_to(@experiment) }
        format.xml  { render :xml => @experiment, :status => :created, :location => @experiment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /experiments/1
  # PUT /experiments/1.xml
  def update
    @experiment = Experiment.find(params[:id])

    respond_to do |format|
      if @experiment.update_attributes(params[:experiment])
        flash[:notice] = 'Experiment was successfully updated.'
        format.html { redirect_to(@experiment) } # redirect to show()
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /experiments/1
  # DELETE /experiments/1.xml
  def destroy
    @experiment = Experiment.find(params[:id])
    @experiment.destroy

    respond_to do |format|
      format.html { redirect_to(experiments_url) }
      format.xml  { head :ok }
    end
  end


########################################################################
  def add_samples
    @experiment=Experiment.find(params[:id])

    # want to list all samples available to the user
    @all_samples=Sample.accessible_to_user(current_user)
    # some might already be assigned to this experiment, some
    # might be assigned to other experiments, and some might not be
    # assigned to anything.
    @my_samples=@experiment.samples
  end


  def update_samples
    @experiment=Experiment.find(params[:id])
    samples=Sample.find(:all)
    id2sample={}
    samples.each do |s| 
      id2sample[s.id]=s
    end

    params.each_pair do |k,v|
      (owner,sample_id)=k.split('_')
      next if sample_id.nil?
      logger.info "debug: sample_id is #{sample_id}"
      sample=id2sample[sample_id.to_i]
#      logger.info "debug: sample is #{sample}"
      next if sample.nil?
      logger.info "debug: sample #{sample.id}, v=#{v}"
      
      case v
        when 'current'
        next if sample.experiment_id == @experiment.id
        sample.experiment_id=@experiment.id
        sample.save
        logger.info "debug: sample #{sample.id} acquired by experiment #{@experiment.id}"

        when 'unassigned'
        next if sample.experiment_id.nil?
        sample.experiment_id=nil
        sample.save
        logger.info "debug: sample #{sample.id} now unassigned"


        when 'other'
        next if !sample.experiment_id.nil? && sample.experiment_id != @experiment.id
        raise "Can't move this sample to another experiment; need to edit experiment #{sample.experiment_id}"

      end
    end
    redirect_to :controller=>:experiments, :action=>:edit, :id=>@experiment.id
  end

end
