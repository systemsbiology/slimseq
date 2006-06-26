require File.dirname(__FILE__) + '/../test_helper'
require 'lab_groups_controller'

# Re-raise errors caught by the controller.
class LabGroupsController; def rescue_action(e) raise e end; end

class LabGroupsControllerTest < Test::Unit::TestCase
  fixtures :lab_groups, :hybridizations, :chip_transactions,
    :users, :roles, :permissions, :users_roles, :permissions_roles

  def setup
    @controller = LabGroupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # lab group management is only accessible to admins
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

    assert_not_nil assigns(:lab_groups)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:lab_group)
  end

  def test_create
    num_lab_groups = LabGroup.count

    post :create, :lab_group => {:name => "The Best Group"}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_lab_groups + 1, LabGroup.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:lab_group)
    assert assigns(:lab_group).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => 1
  end

  def test_update_locked
    # grab the lab_group we're going to use twice
    lab_group1 = LabGroup.find(1)
    lab_group2 = LabGroup.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :lab_group => { :name => "lab1", 
                                            :lock_version => lab_group1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :lab_group => { :name => "lab2", 
                                            :lock_version => lab_group2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "lab1", LabGroup.find(1).name
  end

  def test_destroy_no_associated_transactions
    assert_not_nil LabGroup.find(2)

    post :destroy, :id => 2
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      LabGroup.find(2)
    }
  end
  
  def test_destroy_with_associated_transactions
    assert_not_nil LabGroup.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      LabGroup.find(1)
    }
  end
end
