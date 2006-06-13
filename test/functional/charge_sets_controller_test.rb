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
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:charge_set)
    assert assigns(:charge_set).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    assert_not_nil ChargeSet.find(2)

    post :destroy, :id => 2
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChargeSet.find(2)
    }
  end
  
  def test_destroy_with_associated_charges
    assert_not_nil ChargeSet.find(1)

    post :destroy, :id => 1
    assert_response :success
    assert_template 'list'
    assert_flash_warning

    assert_not_nil ChargeSet.find(1)
  end
end
