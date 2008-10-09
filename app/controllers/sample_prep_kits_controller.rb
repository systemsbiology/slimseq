class SamplePrepKitsController < ApplicationController
  # GET /sample_prep_kits
  # GET /sample_prep_kits.xml
  def index
    @sample_prep_kits = SamplePrepKit.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sample_prep_kits }
    end
  end

  # GET /sample_prep_kits/1
  # GET /sample_prep_kits/1.xml
  def show
    @sample_prep_kit = SamplePrepKit.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @sample_prep_kit }
    end
  end

  # GET /sample_prep_kits/new
  # GET /sample_prep_kits/new.xml
  def new
    @sample_prep_kit = SamplePrepKit.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sample_prep_kit }
    end
  end

  # GET /sample_prep_kits/1/edit
  def edit
    @sample_prep_kit = SamplePrepKit.find(params[:id])
  end

  # POST /sample_prep_kits
  # POST /sample_prep_kits.xml
  def create
    @sample_prep_kit = SamplePrepKit.new(params[:sample_prep_kit])

    respond_to do |format|
      if @sample_prep_kit.save
        flash[:notice] = 'SamplePrepKit was successfully created.'
        format.html { redirect_to(sample_prep_kits_url) }
        format.xml  { render :xml => @sample_prep_kit, :status => :created, :location => @sample_prep_kit }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sample_prep_kit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sample_prep_kits/1
  # PUT /sample_prep_kits/1.xml
  def update
    @sample_prep_kit = SamplePrepKit.find(params[:id])

    respond_to do |format|
      if @sample_prep_kit.update_attributes(params[:sample_prep_kit])
        flash[:notice] = 'SamplePrepKit was successfully updated.'
        format.html { redirect_to(sample_prep_kits_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @sample_prep_kit.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sample_prep_kits/1
  # DELETE /sample_prep_kits/1.xml
  def destroy
    @sample_prep_kit = SamplePrepKit.find(params[:id])
    @sample_prep_kit.destroy

    respond_to do |format|
      format.html { redirect_to(sample_prep_kits_url) }
      format.xml  { head :ok }
    end
  end
end
