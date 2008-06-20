class ChargeSetsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def index
    list
    render :action => 'list'
  end

  def list
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC",
                                        :limit => 4)
  end
  
  def list_all
    @charge_periods = ChargePeriod.find(:all, :order => "name DESC")
    render :action => 'list'
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

    begin
      if @charge_set.update_attributes(params[:charge_set])
        flash[:notice] = 'ChargeSet was successfully updated.'
        redirect_to :action => 'list'
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this charge set."
      @charge_set = ChargeSet.find(params[:id])
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
