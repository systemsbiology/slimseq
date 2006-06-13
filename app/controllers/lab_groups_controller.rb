class LabGroupsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
  end

  def show
    @lab_group = LabGroup.find(params[:id])
  end

  def new
    @lab_group = LabGroup.new
  end

  def create
    @lab_group = LabGroup.new(params[:lab_group])
    if @lab_group.save
      flash[:notice] = 'LabGroup was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @lab_group = LabGroup.find(params[:id])
  end

  def update
    @lab_group = LabGroup.find(params[:id])
    if @lab_group.update_attributes(params[:lab_group])
      flash[:notice] = 'LabGroup was successfully updated.'
      redirect_to :action => 'list', :id => @lab_group
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      LabGroup.find(params[:id]).destroy
      redirect_to :action => 'list'
    rescue
      flash[:warning] = "Cannot delete lab group due to association " +
                        "with chip transactions or hybridizations."
      list
      render :action => 'list'
    end
  end
end
