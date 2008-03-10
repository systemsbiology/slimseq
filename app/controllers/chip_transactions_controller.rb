class ChipTransactionsController < ApplicationController
  attr_reader :totals

  def index
    list_subset
  end

  def list_subset
    # if a chip type was passed in, use it
    if params[:chip_type_id] != nil
      session[:chip_type_id] = params[:chip_type_id]    
    end
    
    # allow admin user to look at any group, but
    # other users should only see their stuff
    if(current_user.staff? || current_user.admin?)
      # if a lab group was passed in, use it,
      # otherwise stick with the session lab group
      if(params[:lab_group_id] != nil)
        session[:lab_group_id] = params[:lab_group_id]
      end
    else
      lab_group = LabGroup.find(params[:lab_group_id])
      if(current_user.lab_groups.include?(lab_group))
        session[:lab_group_id] =  params[:lab_group_id]
      else
        session[:lab_group_id] = nil
      end
    end
    # don't allow listing of all chip transactions
    if session[:lab_group_id] == nil || session[:chip_type_id] ==nil
      flash[:warning] = 'Attempt to access inventory information for a group other than your own.'
      redirect_to :controller => 'inventory', :action => 'index'
    else
      @chip_transactions = 
        ChipTransaction.find_all_in_lab_group_chip_type(session[:lab_group_id],session[:chip_type_id])
      @totals = ChipTransaction.get_chip_totals(@chip_transactions)
      @lab_group_name = LabGroup.find(session[:lab_group_id]).name
      @chip_type_name = ChipType.find(session[:chip_type_id]).name
      render :action => 'list'
    end
  end

  def new
    @chip_transaction = ChipTransaction.new(:lab_group_id => session[:lab_group_id],
                                            :chip_type_id => session[:chip_type_id])
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end

  def create
    begin
      @chip_transaction = ChipTransaction.new(params[:chip_transaction])
      @lab_groups = LabGroup.find_all
      @chip_types = ChipType.find_all
      if @chip_transaction.save
        # grab lab group and chip type for display of subset
        session[:lab_group_id] = @chip_transaction.lab_group_id
        session[:chip_type_id] = @chip_transaction.chip_type_id
        flash[:notice] = 'Chip transaction was successfully created.'
        redirect_to :action => 'list_subset'
      else
        render :action => 'new'
      end
    rescue
      flash[:notice] = 'Item could not be saved, probably because date is incorrect.'
      redirect_to :action => 'new'
    end
  end

  def edit
    @chip_transaction = ChipTransaction.find(params[:id])
    @chip_types = ChipType.find_all
    @lab_groups = LabGroup.find_all
  end

  def update
    @chip_transaction = ChipTransaction.find(params[:id])
    @chip_types = ChipType.find_all
    @lab_groups = LabGroup.find_all

    begin
      if @chip_transaction.update_attributes(params[:chip_transaction])
        flash[:notice] = 'Chip transaction was successfully updated.'
        redirect_to :action => 'list_subset', :id => @chip_transaction
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this chip transaction."
      @chip_transaction = ChipTransaction.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    ChipTransaction.find(params[:id]).destroy
    redirect_to :action => 'list_subset'
  end
  
end
