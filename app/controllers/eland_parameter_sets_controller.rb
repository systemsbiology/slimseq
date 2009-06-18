class ElandParameterSetsController < ApplicationController
  # GET /eland_parameter_sets
  # GET /eland_parameter_sets.xml
  def index
    @eland_parameter_sets = ElandParameterSet.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @eland_parameter_sets }
    end
  end

  # GET /eland_parameter_sets/1
  # GET /eland_parameter_sets/1.xml
  def show
    @eland_parameter_set = ElandParameterSet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @eland_parameter_set }
    end
  end

  # GET /eland_parameter_sets/new
  # GET /eland_parameter_sets/new.xml
  def new
    @eland_parameter_set = ElandParameterSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @eland_parameter_set }
    end
  end

  # GET /eland_parameter_sets/1/edit
  def edit
    @eland_parameter_set = ElandParameterSet.find(params[:id])
  end

  # POST /eland_parameter_sets
  # POST /eland_parameter_sets.xml
  def create
    @eland_parameter_set = ElandParameterSet.new(params[:eland_parameter_set])

    respond_to do |format|
      if @eland_parameter_set.save
        flash[:notice] = 'ElandParameterSet was successfully created.'
        format.html { redirect_to(eland_parameter_sets_url) }
        format.xml  { render :xml => @eland_parameter_set, :status => :created, :location => @eland_parameter_set }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @eland_parameter_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /eland_parameter_sets/1
  # PUT /eland_parameter_sets/1.xml
  def update
    @eland_parameter_set = ElandParameterSet.find(params[:id])

    respond_to do |format|
      if @eland_parameter_set.update_attributes(params[:eland_parameter_set])
        flash[:notice] = 'ElandParameterSet was successfully updated.'
        format.html { redirect_to(eland_parameter_sets_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @eland_parameter_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /eland_parameter_sets/1
  # DELETE /eland_parameter_sets/1.xml
  def destroy
    @eland_parameter_set = ElandParameterSet.find(params[:id])
    @eland_parameter_set.destroy

    respond_to do |format|
      format.html { redirect_to(eland_parameter_sets_url) }
      format.xml  { head :ok }
    end
  end
end
