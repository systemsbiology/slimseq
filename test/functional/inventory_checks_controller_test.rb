require File.dirname(__FILE__) + '/../test_helper'
require 'inventory_checks_controller'

# Re-raise errors caught by the controller.
class InventoryChecksController; def rescue_action(e) raise e end; end

class InventoryChecksControllerTest < Test::Unit::TestCase
  fixtures :inventory_checks, :users, :lab_groups, :chip_types

  def setup
    @controller = InventoryChecksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # inventory check management is only accessible to admins
    # so use that login for all tests
    login_as_admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:inventory_checks)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:inventory_check)
  end

  def test_create
    num_inventory_checks = InventoryCheck.count

    post :create, :inventory_check => { :lab_group_id => lab_groups(:gorilla_group).id,
                                        :chip_type_id => chip_types(:mouse).id,
                                        :date => '2006-02-01',
                                        :number_expected => '20',
                                        :number_counted => '20'
                                      }

    assert_response :redirect
    assert_redirected_to :controller=> 'inventory', :action => 'index'

    assert_equal num_inventory_checks + 1, InventoryCheck.count
  end

  def test_edit
    get :edit, :id => inventory_checks(:early_check).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:inventory_check)
    assert assigns(:inventory_check).valid?
  end

  def test_update
    post :update, :id => inventory_checks(:early_check).id
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => inventory_checks(:early_check).id
  end

  def test_update_locked
    # grab the inventory_check we're going to use twice
    inventory_check1 = inventory_checks(:early_check)
    inventory_check2 = inventory_checks(:early_check)
    
    # update it once, which should sucess
    post :update, :id => inventory_checks(:early_check).id, :inventory_check => { :number_expected => 50, 
                                                :lock_version => inventory_check1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => inventory_checks(:early_check).id, :inventory_check => { :number_expected => 40, 
                                                :lock_version => inventory_check2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal 50,
      InventoryCheck.find( inventory_checks(:early_check).id ).number_expected
  end

  def test_destroy
    assert_not_nil InventoryCheck.find( inventory_checks(:early_check).id )

    post :destroy, :id => inventory_checks(:early_check).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      InventoryCheck.find( inventory_checks(:early_check).id )
    }
  end
end
