class OrganismsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @organisms = Organism.find(:all, :order => "name ASC")
  end

  def show
    @organism = Organism.find(params[:id])
  end

  def new
    @organism = Organism.new
  end

  def create
    @organism = Organism.new(params[:organism])
    if @organism.save
      flash[:notice] = 'Organism was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @organism = Organism.find(params[:id])
  end

  def update
    @organism = Organism.find(params[:id])
    
    begin
      if @organism.update_attributes(params[:organism])
        flash[:notice] = 'Organism was successfully updated.'
        redirect_to :action => 'show', :id => @organism
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this organism."
      @organism = Organism.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    Organism.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
