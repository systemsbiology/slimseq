require File.dirname(__FILE__) + '/../test_helper'
require 'inventory_checks_controller'

# Re-raise errors caught by the controller.
class InventoryChecksController; def rescue_action(e) raise e end; end

class InventoryChecksControllerTest < Test::Unit::TestCase
  fixtures :inventory_checks,
    :users, :roles, :permissions, :users_roles, :permissions_roles

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

    post :create, :inventory_check => { :lab_group_id => '1',
                                        :chip_type_id => '1',
                                        :date => '2006-02-01',
                                        :number_expected => '20',
                                        :number_counted => '20'
                                      }

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_inventory_checks + 1, InventoryCheck.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:inventory_check)
    assert assigns(:inventory_check).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => 1
  end

  def test_destroy
    assert_not_nil InventoryCheck.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      InventoryCheck.find(1)
    }
  end
end
