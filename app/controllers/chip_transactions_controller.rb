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
    if(current_user.admin?)
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
      @totals = Hash.new(0)
      for transaction in @chip_transactions
        if transaction.acquired != nil
          @totals['acquired'] += transaction.acquired
          @totals['chips'] += transaction.acquired
        end
        if transaction.used != nil
          @totals['used'] += transaction.used
          @totals['chips'] -= transaction.used
        end
        if transaction.traded_sold != nil
          @totals['traded_sold'] += transaction.traded_sold
          @totals['chips'] -= transaction.traded_sold
        end
        if transaction.borrowed_in != nil
          @totals['borrowed_in'] += transaction.borrowed_in
          @totals['chips'] += transaction.borrowed_in
        end
        if transaction.returned_out != nil
          @totals['returned_out'] += transaction.returned_out
          @totals['chips'] -= transaction.returned_out
        end
        if transaction.borrowed_out != nil
          @totals['borrowed_out'] += transaction.borrowed_out
          @totals['chips'] -= transaction.borrowed_out
        end
        if transaction.returned_in != nil
          @totals['returned_in'] += transaction.returned_in
          @totals['chips'] += transaction.returned_in
        end
      end
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
        flash[:notice] = 'ChipTransaction was successfully created.'
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
