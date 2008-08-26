class ChipTransactionsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

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
    if(current_user.staff_or_admin?)
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

  def buy
    new
  end

  def borrow
    new
  end

  def borrow_create
    begin
      @chip_transaction = ChipTransaction.new(params[:chip_transaction])
      
      @lab_groups = LabGroup.find(:all)
      @chip_types = ChipType.find(:all)

      @borrowing_from_group = 
        LabGroup.find(params[:borrowing_from_lab_group_id])

      # automatically set the description
      @chip_transaction.description = "Borrowed from " + 
        @borrowing_from_group.name

      @secondary_transaction = ChipTransaction.new(
        :date => @chip_transaction.date,
        :lab_group_id => @borrowing_from_group.id,
        :chip_type_id => @chip_transaction.chip_type_id,
        :description => "Borrowed by " +  @chip_transaction.lab_group.name,
        :borrowed_out => @chip_transaction.borrowed_in
      )

      if @chip_transaction.save && @secondary_transaction.save
        # grab lab group and chip type for display of subset
        session[:lab_group_id] = @chip_transaction.lab_group_id
        session[:chip_type_id] = @chip_transaction.chip_type_id

        flash[:notice] = 'Chip transaction was successfully created.'
        redirect_to :action => 'list_subset'
      else
        render :action => 'borrow'
      end
    rescue
      flash[:notice] = 'Item could not be saved, probably because date is incorrect.'
      redirect_to :action => 'borrow'
    end
  end
  
  def return_borrowed
    new
  end

  def return_create
    begin
      @chip_transaction = ChipTransaction.new(params[:chip_transaction])
      
      @lab_groups = LabGroup.find(:all)
      @chip_types = ChipType.find(:all)

      @returning_to_group = 
        LabGroup.find(params[:returning_to_lab_group_id])

      # automatically set the description
      @chip_transaction.description = "Returned to " + 
        @returning_to_group.name

      @secondary_transaction = ChipTransaction.new(
        :date => @chip_transaction.date,
        :lab_group_id => @returning_to_group.id,
        :chip_type_id => @chip_transaction.chip_type_id,
        :description => "Returned by " +  @chip_transaction.lab_group.name,
        :returned_in => @chip_transaction.returned_out
      )

      if @chip_transaction.save && @secondary_transaction.save
        # grab lab group and chip type for display of subset
        session[:lab_group_id] = @chip_transaction.lab_group_id
        session[:chip_type_id] = @chip_transaction.chip_type_id

        flash[:notice] = 'Chip transaction was successfully created.'
        redirect_to :action => 'list_subset'
      else
        render :action => 'return_borrowed'
      end
    rescue
      flash[:notice] = 'Item could not be saved, probably because date is incorrect.'
      redirect_to :action => 'return_borrowed'
    end
  end
  
  def create
    begin
      @chip_transaction = ChipTransaction.new(params[:chip_transaction])
      
      @lab_groups = LabGroup.find(:all)
      @chip_types = ChipType.find(:all)

      if(params[:transaction_type] == "borrow")
        @borrowing_from_group = 
          LabGroup.find(params[:borrowing_from_lab_group_id])
        
        # automatically set the description
        @chip_transaction.description = "Borrowed from " + 
          @borrowing_from_group.name
        
        @secondary_transaction = ChipTransaction.new(
          :date => @chip_transaction.date,
          :lab_group_id => @borrowing_from_group.id,
          :chip_type_id => @chip_transaction.chip_type_id,
          :description => "Borrowed by " +  @chip_transaction.lab_group.name,
          :borrowed_out => @chip_transaction.borrowed_in
        )
      elsif(params[:transaction_type] == "return")
        @returning_to_group = 
          LabGroup.find(params[:returning_to_lab_group_id])
        
        # automatically set the description
        @chip_transaction.description = "Returned to " + 
          @returning_to_group.name
        
        @secondary_transaction = ChipTransaction.new(
          :date => @chip_transaction.date,
          :lab_group_id => @returning_to_group.id,
          :chip_type_id => @chip_transaction.chip_type_id,
          :description => "Returned by " +  @chip_transaction.lab_group.name,
          :returned_in => @chip_transaction.returned_out
        )
      end

      if @chip_transaction.save
        # grab lab group and chip type for display of subset
        session[:lab_group_id] = @chip_transaction.lab_group_id
        session[:chip_type_id] = @chip_transaction.chip_type_id

        # if there's a secondary transaction (e.g. borrow), save that too
        if(@secondary_transaction != nil)
          @secondary_transaction.save
        end
        
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
    @chip_types = ChipType.find(:all)
    @lab_groups = LabGroup.find(:all)
  end

  def update
    @chip_transaction = ChipTransaction.find(params[:id])
    @chip_types = ChipType.find(:all)
    @lab_groups = LabGroup.find(:all)

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
