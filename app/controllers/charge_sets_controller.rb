class ChargeSetsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC")
  end

  def new
    @charge_set = ChargeSet.new
    populate_for_dropdown
  end

  def create
    @charge_set = ChargeSet.new(params[:charge_set])
    populate_for_dropdown
    if @charge_set.save
      flash[:notice] = 'ChargeSet was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @charge_set = ChargeSet.find(params[:id])
    populate_for_dropdown
  end

  def update
    @charge_set = ChargeSet.find(params[:id])
    populate_for_dropdown
    if @charge_set.update_attributes(params[:charge_set])
      flash[:notice] = 'ChargeSet was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      ChargeSet.find(params[:id]).destroy
      redirect_to :action => 'list'
    rescue
      flash[:warning] = "Cannot delete charge set due to association " +
                        "with one or more charges."
      list
      render :action => 'list'
    end
  end
  
  private
  def populate_for_dropdown
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC")
  end
end
