require File.dirname(__FILE__) + '/../test_helper'
require 'chip_transactions_controller'

# Re-raise errors caught by the controller.
class ChipTransactionsController; def rescue_action(e) raise e end; end

class ChipTransactionsControllerTest < Test::Unit::TestCase
  fixtures :lab_groups, :chip_types, :chip_transactions

  def setup
    @controller = ChipTransactionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # just doing tests as admin for the time being
    login_as_admin
  end

  def test_index
    get :list_subset

    assert_redirected_to :controller => 'inventory', :action => 'index'
  end

  def test_list_subset
    get :list_subset, :lab_group_id => lab_groups(:gorilla_group).id,
      :chip_type_id => chip_types(:mouse).id

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:chip_transactions)
  end

  def test_list_subset_no_parameters
    get :list_subset

    assert_redirected_to :controller => 'inventory', :action => 'index'
    #assert_not_nil assigns(:chip_transactions)
  end  

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:chip_transaction)
  end

  def test_buy
    get :buy

    assert_response :success
    assert_template 'buy'

    assert_not_nil assigns(:chip_transaction)
  end

  def test_borrow
    get :borrow

    assert_response :success
    assert_template 'borrow'

    assert_not_nil assigns(:chip_transaction)
  end

  def test_return_borrowed
    get :return_borrowed

    assert_response :success
    assert_template 'return_borrowed'

    assert_not_nil assigns(:chip_transaction)
  end

  def test_borrow_create
    num_chip_transactions = ChipTransaction.count

    post :borrow_create,
      :borrowing_from_lab_group_id => lab_groups(:monkey_group).id,
      :chip_transaction => {
        :lab_group_id => lab_groups(:gorilla_group).id,
        :chip_type_id => chip_types(:alligator).id,
        :date => '2006-02-01',
        :borrowed_in => '5'
      }

    assert_response :redirect
    assert_redirected_to :action => 'list_subset'
    assert_no_flash_warning

    assert_equal num_chip_transactions + 2, ChipTransaction.count
    assert_not_nil ChipTransaction.find(:first, :conditions =>
      { :lab_group_id => lab_groups(:gorilla_group).id,
       :chip_type_id => chip_types(:alligator).id,
       :date => '2006-02-01',
       :borrowed_in => '5',
       :description => 'Borrowed from Monkeys' }
    )
    assert_not_nil ChipTransaction.find(:first, :conditions =>
      { :lab_group_id => lab_groups(:monkey_group).id,
        :chip_type_id => chip_types(:alligator).id,
        :date => '2006-02-01',
        :borrowed_out => '5',
        :description => 'Borrowed by Gorillaz' }
    )
  end

  def test_return_create
    num_chip_transactions = ChipTransaction.count

    post :return_create,
      :returning_to_lab_group_id => lab_groups(:monkey_group).id,
      :chip_transaction => {
        :lab_group_id => lab_groups(:gorilla_group).id,
        :chip_type_id => chip_types(:alligator).id,
        :date => '2006-02-01',
        :returned_out => '5'
      }

    assert_response :redirect
    assert_redirected_to :action => 'list_subset'
    assert_no_flash_warning

    assert_equal num_chip_transactions + 2, ChipTransaction.count
    assert_not_nil ChipTransaction.find(:first, :conditions =>
      { :lab_group_id => lab_groups(:gorilla_group).id,
       :chip_type_id => chip_types(:alligator).id,
       :date => '2006-02-01',
       :returned_out => '5',
       :description => 'Returned to Monkeys' }
    )
    assert_not_nil ChipTransaction.find(:first, :conditions =>
      { :lab_group_id => lab_groups(:monkey_group).id,
        :chip_type_id => chip_types(:alligator).id,
        :date => '2006-02-01',
        :returned_in => '5',
        :description => 'Returned by Gorillaz' }
    )
  end
  
  def test_create
    num_chip_transactions = ChipTransaction.count

    post :create, :chip_transaction => {  :lab_group_id => lab_groups(:gorilla_group).id,
                                          :chip_type_id => chip_types(:alligator).id,
                                          :date => '2006-02-01',
                                          :description => 'Bought some chips',
                                          :acquired => '180',
                                          :used => '0',
                                          :traded_sold => '0',
                                          :borrowed_in => '0',
                                          :returned_out => '0',
                                          :borrowed_out => '0',
                                          :returned_in => '0'
                                       }

    assert_response :redirect
    assert_redirected_to :action => 'list_subset'
    assert_no_flash_warning

    assert_equal num_chip_transactions + 1, ChipTransaction.count
  end

  def test_create_no_description
    num_chip_transactions = ChipTransaction.count

    post :create, :chip_transaction => {  :lab_group_id => lab_groups(:gorilla_group).id,
                                          :chip_type_id => chip_types(:mouse).id,
                                          :date => '2006-02-01',
                                          :acquired => '180',
                                          :used => '0',
                                          :traded_sold => '0',
                                          :borrowed_in => '0',
                                          :returned_out => '0',
                                          :borrowed_out => '0',
                                          :returned_in => '0'
                                       }

    assert_response :success
    assert_template "chip_transactions/new"
    assert_errors

    assert_equal num_chip_transactions, ChipTransaction.count
  end

  def test_edit
    get :edit, :id => chip_transactions(:acquired).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:chip_transaction)
    assert assigns(:chip_transaction).valid?
  end

  def test_update
    post :update, :id => chip_transactions(:acquired).id
    assert_response :redirect
    assert_redirected_to :action => 'list_subset', :id => chip_transactions(:acquired).id
  end

  def test_update_locked
    # grab the chip_transaction we're going to use twice
    chip_transaction1 = chip_transactions(:acquired)
    chip_transaction2 = chip_transactions(:acquired)
    
    # update it once, which should sucess
    post :update, :id => chip_transactions(:acquired).id, :chip_transaction => { :description => "chip_transaction1", 
                                                :lock_version => chip_transaction1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => chip_transactions(:acquired).id, :chip_transaction => { :description => "chip_transaction2", 
                                                :lock_version => chip_transaction2.lock_version }                                            

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "chip_transaction1",
      ChipTransaction.find( chip_transactions(:acquired).id ).description
  end

  def test_destroy
    assert_not_nil ChipTransaction.find( chip_transactions(:acquired).id )

    post :destroy, :id => chip_transactions(:acquired).id
    assert_response :redirect
    assert_redirected_to :action => 'list_subset'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChipTransaction.find( chip_transactions(:acquired).id )
    }
  end

end
