require File.dirname(__FILE__) + '/../test_helper'
require 'charges_controller'

# Re-raise errors caught by the controller.
class ChargesController; def rescue_action(e) raise e end; end

class ChargesControllerTest < Test::Unit::TestCase
  fixtures :charges

  def setup
    @controller = ChargesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # use admin login for all tests for the moment
    login_as_admin
  end

  def test_list_within_charge_set_given_charge_set_id
    get :list_within_charge_set, :charge_set_id => 1

    assert_response :success
    assert_template 'list_within_charge_set'

    assert_not_nil assigns(:charges)
  end

  def test_new_given_charge_set_id
    get :new, :charge_set_id => 1

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:charge)
  end

  def test_new_using_template
    test_new_given_charge_set_id
    
    post :new, :charge_template_id => 1
    
    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:charge)
  end

  def test_create
    num_charges = Charge.count

    post :create, :charge => { :charge_set_id => 1,
                               :date => '2006-03-07',
                               :chips_used => 1,
                               :description => 'Sample B',
                               :chip_cost => 400,
                               :labeling_cost => 280,
                               :hybridization_cost => 100,
                               :qc_cost => 0,
                               :other_cost => 0}

    assert_response :redirect
    assert_redirected_to :action => 'list_within_charge_set'

    assert_equal num_charges + 1, Charge.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:charge)
    assert assigns(:charge).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list_within_charge_set'
  end

  def test_move
    post :move, :charge_set_id => 2, :selected_charges => {'2' => '1'}
    
    assert_response :success
    assert_template 'list_within_charge_set'

    # assert non-selected charge doesn't move    
    assert_equal 1, Charge.find(1).charge_set_id
    # assert selected charge does move
    assert_equal 2, Charge.find(2).charge_set_id
  end

  def test_destroy
    assert_not_nil Charge.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list_within_charge_set'

    assert_raise(ActiveRecord::RecordNotFound) {
      Charge.find(1)
    }
  end
end
