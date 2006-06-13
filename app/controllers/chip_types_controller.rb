class ChipTypesController < ApplicationController
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
    @chip_type = ChipType.new(params[:chip_type])
    
    # if a new organism was specified, use that name
    if(params[:organism] != nil && params[:organism].size > 0)
      org = Organism.new(:name => params[:organism])
      org.save
      @chip_type.update_attribute('default_organism_id', org.id)
    end
    
    if @chip_type.save
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
    
    if @chip_type.update_attributes(params[:chip_type])
      # if a new organism was specified, use that name
      if(params[:organism] != nil && params[:organism].size > 0)
        org = Organism.new(:name => params[:organism])
        org.save
        @chip_type.update_attribute('default_organism_id', org.id)
      end
    
      flash[:notice] = 'ChipType was successfully updated.'
      redirect_to :action => 'list', :id => @chip_type
    else
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
