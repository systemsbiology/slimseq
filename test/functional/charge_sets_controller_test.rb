require File.dirname(__FILE__) + '/../test_helper'
require 'charge_sets_controller'

# Re-raise errors caught by the controller.
class ChargeSetsController; def rescue_action(e) raise e end; end

class ChargeSetsControllerTest < Test::Unit::TestCase
  fixtures :charge_sets, :charges, :lab_groups

  def setup
    @controller = ChargeSetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # use admin login for all tests for the moment
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

    assert_not_nil assigns(:charge_periods)
  end

  def test_list_all
    get :list_all

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:charge_periods)
  end
  
  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:charge_set)
  end

  def test_create
    num_charge_sets = ChargeSet.count

    post :create, :charge_set => { :lab_group_id => 1,
                                   :charge_period_id => 2,
                                   :name => 'Mouse',
                                   :budget_manager => 'Some Guy',
                                   :budget => '11235813'}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_charge_sets + 1, ChargeSet.count
  end

  def test_edit
    get :edit, :id => charge_sets(:mouse_jan).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:charge_set)
    assert assigns(:charge_set).valid?
  end

  def test_update
    post :update, :id => charge_sets(:mouse_jan).id
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked
    # grab the charge set we're going to use twice
    set1 = charge_sets(:mouse_jan)
    set2 = charge_sets(:mouse_jan)
    
    # update it once, which should sucess
    post :update, :id => charge_sets(:mouse_jan).id, :charge_set => { :name => "set1", 
                                                :lock_version => set1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => charge_sets(:mouse_jan).id, :charge_set => { :name => "set2", 
                                                :lock_version => set2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "set1", ChargeSet.find( charge_sets(:mouse_jan).id ).name
  end

  def test_destroy
    assert_not_nil ChargeSet.find( charge_sets(:alligator_jan).id )

    post :destroy, :id => charge_sets(:alligator_jan).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChargeSet.find(2)
    }
  end
  
  def test_destroy_with_associated_charges
    assert_not_nil ChargeSet.find( charge_sets(:mouse_jan).id )

    post :destroy, :id => charge_sets(:mouse_jan).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChargeSet.find( charge_sets(:mouse_jan).id )
    }
  end
end
