class NamingSchemesController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
  end

  def new
    @naming_scheme = NamingScheme.new
  end

  def create
    @naming_scheme = NamingScheme.new(params[:naming_scheme])
    if @naming_scheme.save
      flash[:notice] = 'Naming scheme was successfully created.'
      redirect_to :action => 'list'
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
        redirect_to :action => 'list'
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
      redirect_to :action => 'list'
    rescue
      flash[:warning] = "Cannot delete naming scheme due to association " +
                        "with naming elements."
      list
      render :action => 'list'
    end
  end

end
