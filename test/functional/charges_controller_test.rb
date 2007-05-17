require File.dirname(__FILE__) + '/../test_helper'
require 'charges_controller'
require 'assert_select'
require 'html_selector'
Test::Unit::TestCase.send :include, Test::Unit::AssertSelect

# Re-raise errors caught by the controller.
class ChargesController; def rescue_action(e) raise e end; end

class ChargesControllerTest < Test::Unit::TestCase
  fixtures :charges, :charge_sets, :charge_templates

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

  def test_update_locked
    # grab the charge we're going to use twice
    charge1 = Charge.find(1)
    charge2 = Charge.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :charge => { :description => "charge1", 
                                                :lock_version => charge1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :charge => { :description => "charge2", 
                                                :lock_version => charge2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "charge1", Charge.find(1).description
  end

  def test_bulk_edit_valid_change
    get :list_within_charge_set, :charge_set_id => 1
  
    post :bulk_edit_move_or_destroy, :selected_charges => {'2' => '1'},
         :field_name => "chip_cost", :field_value => "500",
         :move_charge_set_id => 2, :commit => "Set Field"

    assert_response :success
    assert_template 'list_within_charge_set'
    expected_heading = "Listing Charges for " + @charge_sets['mouse_jan']['name']
    assert_select "h2", expected_heading
    
    # assert non-selected charge didn't change
    assert_equal 400, Charge.find(1).chip_cost
    # assert selected charge did change chip cost
    assert_equal 500, Charge.find(2).chip_cost
  end
  
  def test_bulk_edit_invalid_change
    post :bulk_edit_move_or_destroy, :selected_charges => {'2' => '1'},
         :field_name => "chip_cost", :field_value => "adsf",
         :commit => "Set Field"

    assert_response :success
    assert_template 'list_within_charge_set'
    assert_flash_warning
    
    # assert non-selected charge didn't change
    assert_equal 400, Charge.find(1).chip_cost
    # assert selected charge didn't change
    assert_equal 0, Charge.find(2).chip_cost
  end

  def test_bulk_move
    post :bulk_edit_move_or_destroy, :move_charge_set_id => 2, :selected_charges => {'2' => '1'},
         :commit => "Move Charges To This Charge Set"
    
    assert_response :success
    assert_template 'list_within_charge_set'
    expected_heading = "Listing Charges for " + @charge_sets['alligator_jan']['name']
    assert_select "h2", expected_heading

    # assert non-selected charge doesn't move    
    assert_equal 1, Charge.find(1).charge_set_id
    # assert selected charge does move
    assert_equal 2, Charge.find(2).charge_set_id
  end

  def test_bulk_destroy
    get :list_within_charge_set, :charge_set_id => 1
    
    post :bulk_edit_move_or_destroy, :selected_charges => {'1' => '1', '2' => '1'},
         :move_charge_set_id => 2, :commit => "Delete Charges"
    
    assert_response :success
    assert_template 'list_within_charge_set'
    expected_heading = "Listing Charges for " + @charge_sets['mouse_jan']['name']
    assert_select "h2", expected_heading

    # assert that destroys have taken place
    assert_raise(ActiveRecord::RecordNotFound) {
      Charge.find(1)
    }
    assert_raise(ActiveRecord::RecordNotFound) {
      Charge.find(2)
    }
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
