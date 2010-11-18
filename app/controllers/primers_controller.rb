class PrimersController < ApplicationController
  # GET /primers
  # GET /primers.xml
  def index
    @primers = Primer.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @primers }
    end
  end

  # GET /primers/1.xml
  def show
    @primer = Primer.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @primer }
    end
  end

  # GET /primers/new
  # GET /primers/new.xml
  def new
    @primer = Primer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @primer }
    end
  end

  # GET /primers/1/edit
  def edit
    @primer = Primer.find(params[:id])
  end

  # POST /primers
  # POST /primers.xml
  def create
    @primer = Primer.new(params[:primer])

    respond_to do |format|
      if @primer.save
        format.html { redirect_to(primers_url, :notice => 'Primer was successfully created.') }
        format.xml  { render :xml => @primer, :status => :created, :location => @primer }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @primer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /primers/1
  # PUT /primers/1.xml
  def update
    @primer = Primer.find(params[:id])

    respond_to do |format|
      if @primer.update_attributes(params[:primer])
        format.html { redirect_to(primers_url, :notice => 'Primer was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @primer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /primers/1
  # DELETE /primers/1.xml
  def destroy
    @primer = Primer.find(params[:id])
    @primer.destroy

    respond_to do |format|
      format.html { redirect_to(primers_url) }
      format.xml  { head :ok }
    end
  end
end
