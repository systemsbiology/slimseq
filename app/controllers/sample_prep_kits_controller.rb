=begin rapidoc
name:: /sample_prep_kits

This resource can be used to list a summary of all sample_prep_kits, or show details for 
a particular sample_prep_kit.<br><br>

Each sample_prep_kit belongs to a particular lab group. A sample_prep_kit can be associated 
with any number of samples.
=end

class SamplePrepKitsController < ApplicationController
  before_filter :login_required

=begin rapidoc
url:: /sample_prep_kits
method:: GET
example:: <%= SiteConfig.site_url %>/sample_prep_kits
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(SamplePrepKit.find(:all, :limit => 5).collect{|x| x.detail_hash}) %>
xml:: <%= SamplePrepKit.find(:all, :limit => 5).collect{|x| x.detail_hash}.to_xml %>
return:: A list of all summary information on all sample_prep_kits

Get a list of all sample_prep_kits, which doesn't have all the details that are 
available when retrieving single sample_prep_kits (see GET /sample_prep_kits/[sample_prep_kit id]).
=end
  
  # GET /sample_prep_kits
  # GET /sample_prep_kits.xml
  # GET /sample_prep_kits.json
  def index
    @sample_prep_kits = SamplePrepKit.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sample_prep_kits.
        collect{|x| x.detail_hash}
      }
      format.json  { render :json => @sample_prep_kits.
        collect{|x| x.detail_hash}
      }
    end
  end

=begin rapidoc
url:: /sample_prep_kits/[sample_prep_kit id]
method:: GET
example:: <%= SiteConfig.site_url %>/sample_prep_kits/5.json
access:: HTTP Basic authentication, Customer access or higher
json:: <%= JsonPrinter.render(SamplePrepKit.find(:first).detail_hash) %>
xml:: <%= SamplePrepKit.find(:first).detail_hash.to_xml %>
return:: Detailed attributes of a particular sample_prep_kit

Get detailed information about a single sample_prep_kit.
=end
  
  # GET /sample_prep_kits/1
  # GET /sample_prep_kits/1.xml
  # GET /sample_prep_kits/1.json
  def show
    @sample_prep_kit = SamplePrepKit.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @sample_prep_kit.detail_hash }
      format.json  { render :json => @sample_prep_kit.detail_hash }
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
