class NamingSchemesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def index
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @naming_schemes }
      format.json  { render :json => @naming_schemes.
        collect{|x| x.summary_hash}.to_json 
      }
    end
  end

  def show
    @naming_scheme = NamingScheme.find(params[:id])
    
    respond_to do |format|
      format.xml  { render :xml => @naming_scheme }
      format.json  { render :json => @naming_scheme.detail_hash.to_json }
    end    
  end

  def new
    @naming_scheme = NamingScheme.new
  end

  def create
    @naming_scheme = NamingScheme.new(params[:naming_scheme])
    if @naming_scheme.save
      flash[:notice] = 'Naming scheme was successfully created.'
      redirect_to naming_schemes_url
    else
      render :action => 'new'
    end
  end

  def rename
    @naming_scheme = NamingScheme.find(params[:id])
  end

  def update
    @naming_scheme = NamingScheme.find(params[:id])
    
    # catch StaleObjectErrors
    begin
      if @naming_scheme.update_attributes(params[:naming_scheme])  
        flash[:notice] = 'Naming scheme was successfully updated.'
        redirect_to naming_schemes_url
      else
        render :action => 'rename'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this naming scheme."
      @naming_scheme = NamingScheme.find(params[:id])
      render :action => 'rename'
    end
  end

  def destroy
    begin
      NamingScheme.find(params[:id]).destroy
      redirect_to naming_schemes_url
    rescue
      flash[:warning] = "Cannot delete naming scheme due to association " +
                        "with naming elements."
      list
      render :action => 'list'
    end
  end

end
