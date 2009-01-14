=begin rapidoc
name:: /instruments

This resource can be used to list a summary of all instruments, or show details for 
a particular instrument.<br><br>

An instrument can be associated with any number of flow cells, once they have been sequenced.
=end

class InstrumentsController < ApplicationController

=begin rapidoc
url:: /instruments
method:: GET
example:: <%= SiteConfig.site_url %>/instruments
access:: No authentication required
json:: <%= JsonPrinter.render(Instrument.find(:all, :limit => 5).collect{|x| x.detail_hash}) %>
xml:: <%= Instrument.find(:all, :limit => 5).collect{|x| x.detail_hash}.to_xml %>
return:: A list of all summary information on all instruments

Get a list of all instruments, which doesn't have all the details that are 
available when retrieving single instruments (see GET /instruments/[instrument id]).
=end
  
  # GET /instruments
  # GET /instruments.xml
  # GET /instruments.json
  def index
    @instruments = Instrument.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @instruments.
        collect{|x| x.detail_hash}
      }
      format.json  { render :json => @instruments.
        collect{|x| x.detail_hash}
      }
    end
  end

=begin rapidoc
url:: /instruments/[instrument id]
method:: GET
example:: <%= SiteConfig.site_url %>/instruments/5.json
access:: No authentication required
json:: <%= JsonPrinter.render(Instrument.find(:first).detail_hash) %>
xml:: <%= Instrument.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular instrument

Get detailed information about a single instrument.
=end
  
  # GET /instruments/1.xml
  # GET /instruments/1.json
  def show
    @instrument = Instrument.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @instrument.detail_hash }
      format.json  { render :json => @instrument.detail_hash }
    end
  end

  # GET /instruments/new
  # GET /instruments/new.xml
  def new
    @instrument = Instrument.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @instrument }
    end
  end

  # GET /instruments/1/edit
  def edit
    @instrument = Instrument.find(params[:id])
  end

  # POST /instruments
  # POST /instruments.xml
  def create
    @instrument = Instrument.new(params[:instrument])

    respond_to do |format|
      if @instrument.save
        flash[:notice] = 'Instrument was successfully created.'
        format.html { redirect_to(instruments_url) }
        format.xml  { render :xml => @instrument, :status => :created, :location => @instrument }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @instrument.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /instruments/1
  # PUT /instruments/1.xml
  def update
    @instrument = Instrument.find(params[:id])

    respond_to do |format|
      if @instrument.update_attributes(params[:instrument])
        flash[:notice] = 'Instrument was successfully updated.'
        format.html { redirect_to(instruments_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @instrument.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /instruments/1
  # DELETE /instruments/1.xml
  def destroy
    @instrument = Instrument.find(params[:id])
    @instrument.destroy

    respond_to do |format|
      format.html { redirect_to(instruments_url) }
      format.xml  { head :ok }
    end
  end
end
