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
    get :list_subset, :lab_group_id => 1, :chip_type_id => 1

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

  def test_create
    num_chip_transactions = ChipTransaction.count

    post :create, :chip_transaction => {  :lab_group_id => '1',
                                          :chip_type_id => '1',
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

    assert_equal num_chip_transactions + 1, ChipTransaction.count
  end

  def test_create_no_description
    num_chip_transactions = ChipTransaction.count

    post :create, :chip_transaction => {  :lab_group_id => '1',
                                          :chip_type_id => '1',
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
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:chip_transaction)
    assert assigns(:chip_transaction).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list_subset', :id => 1
  end

  def test_destroy
    assert_not_nil ChipTransaction.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list_subset'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChipTransaction.find(1)
    }
  end
  
#  def teardown
#    #breakpoint();
#    ChipTransaction.delete_all
#    ChipType.delete_all
#    LabGroup.delete_all
#  end
end
