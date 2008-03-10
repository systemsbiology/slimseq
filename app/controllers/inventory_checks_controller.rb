class InventoryChecksController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @inventory_checks = InventoryCheck.find(:all, :order => 'date DESC')
  end

  def new
    populate_arrays_from_tables
    
    @inventory_check = InventoryCheck.new
    if(params[:expected] != nil)
      @inventory_check.number_expected = params[:expected]
    end
    if(params[:lab_group_id] != nil)
      @inventory_check.lab_group_id = params[:lab_group_id]
    end
    if(params[:chip_type_id] != nil)
      @inventory_check.chip_type_id = params[:chip_type_id]
    end    
  end

  def create
    populate_arrays_from_tables
  
    @inventory_check = InventoryCheck.new(params[:inventory_check])
    if @inventory_check.save
      flash[:notice] = 'InventoryCheck was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    populate_arrays_from_tables
  
    @inventory_check = InventoryCheck.find(params[:id])
  end

  def update
    populate_arrays_from_tables
    
    @inventory_check = InventoryCheck.find(params[:id])
    begin
      if @inventory_check.update_attributes(params[:inventory_check])
        flash[:notice] = 'InventoryCheck was successfully updated.'
        redirect_to :action => 'list', :id => @inventory_check
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this inventory check."
      @inventory_check = InventoryCheck.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    InventoryCheck.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  private
  def populate_arrays_from_tables
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")    
  end
end
