class ChargeTemplatesController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  def list
    @charge_templates = ChargeTemplate.find(:all, :order => "name ASC")
  end

  def new
    @charge_template = ChargeTemplate.new
  end

  def create
    @charge_template = ChargeTemplate.new(params[:charge_template])
    if @charge_template.save
      flash[:notice] = 'ChargeTemplate was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @charge_template = ChargeTemplate.find(params[:id])
  end

  def update
    @charge_template = ChargeTemplate.find(params[:id])
    if @charge_template.update_attributes(params[:charge_template])
      flash[:notice] = 'ChargeTemplate was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    ChargeTemplate.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
