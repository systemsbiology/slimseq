class QualityTracesController < ApplicationController
  before_filter :login_required
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @quality_trace_pages, @quality_traces = paginate :quality_traces, :per_page => 10
  end

  def show
    @quality_trace = QualityTrace.find(params[:id])
  end

  def new
    @quality_trace = QualityTrace.new
  end

  def create
    @quality_trace = QualityTrace.new(params[:quality_trace])
    if @quality_trace.save
      flash[:notice] = 'QualityTrace was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @quality_trace = QualityTrace.find(params[:id])
  end

  def update
    @quality_trace = QualityTrace.find(params[:id])
    if @quality_trace.update_attributes(params[:quality_trace])
      flash[:notice] = 'QualityTrace was successfully updated.'
      redirect_to :action => 'show', :id => @quality_trace
    else
      render :action => 'edit'
    end
  end

  def destroy
    QualityTrace.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
