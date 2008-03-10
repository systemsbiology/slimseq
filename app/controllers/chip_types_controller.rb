class ChipTypesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def index
    list
    render :action => 'list'
  end

  def list
    populate_arrays_from_tables
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end

  def new
    populate_arrays_from_tables
    @chip_type = ChipType.new
  end

  def create
    populate_arrays_from_tables
    @chip_type = ChipType.new(params[:chip_type])
    
    # if a new organism was specified, use that name
    if(@chip_type.organism_id == -1)
      @organism = Organism.new(:name => params[:organism])
      if @organism.save
        @chip_type.update_attribute('organism_id', @organism.id)
      end
    end
    
    # try to save the new chip type
    if(@chip_type.save)
      flash[:notice] = 'ChipType was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    populate_arrays_from_tables
    @chip_type = ChipType.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    @chip_type = ChipType.find(params[:id])
    
    # catch StaleObjectErrors
    begin
      if @chip_type.update_attributes(params[:chip_type])
        # if a new organism was specified, use that name
        if(params[:organism] != nil && params[:organism].size > 0)
          @organism = Organism.new(:name => params[:organism])
          @organism.save
          @chip_type.update_attribute('organism_id', @organism.id)
        end
      
        flash[:notice] = 'ChipType was successfully updated.'
        redirect_to :action => 'list', :id => @chip_type
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this chip type."
      @chip_type = ChipType.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    begin
      ChipType.find(params[:id]).destroy
      redirect_to :action => 'list'
    rescue
      flash[:warning] = "Cannot delete chip type due to association " +
                        "with chip transactions or hybridizations."
      list
      render :action => 'list'
    end
  end
  
  private
  def populate_arrays_from_tables
    @organisms = Organism.find(:all, :order => "name ASC")
  end
end
