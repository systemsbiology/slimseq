require File.dirname(__FILE__) + '/../test_helper'
require 'charge_periods_controller'

# Re-raise errors caught by the controller.
class ChargePeriodsController; def rescue_action(e) raise e end; end

class ChargePeriodsControllerTest < Test::Unit::TestCase
  fixtures :charge_periods, :charge_sets

  def setup
    @controller = ChargePeriodsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # use admin login for all tests for the moment
    login_as_admin
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:charge_period)
  end

  def test_create
    num_charge_periods = ChargePeriod.count

    post :create, :charge_period => { :name => "2006-02-25 to 2006-03-24" }

    assert_response :redirect
    assert_redirected_to :controller => 'charge_sets', :action => 'list'

    assert_equal num_charge_periods + 1, ChargePeriod.count
  end

  def test_create_duplicate_name
    num_charge_periods = ChargePeriod.count

    post :create, :charge_period => { :name => "2006-01-25 to 2006-02-24" }

    assert_response :success
    assert_template 'new'
    assert_errors

    assert_equal num_charge_periods, ChargePeriod.count
  end

  def test_edit
    get :edit, :id => charge_periods(:january).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:charge_period)
    assert assigns(:charge_period).valid?
  end

  def test_update
    post :update, :id => charge_periods(:january).id,
         :charge_period => { :name => "2006-03-25 to 2006-04-24" }
    assert_response :redirect
    assert_redirected_to :controller => 'charge_sets', :action => 'list'
  end

  def test_update_duplicate_name
    post :update, :id => charge_periods(:january).id,
         :charge_period => { :name => "2006-01-25 to 2006-02-24" }
    assert_response :success
    assert_template 'edit'
    assert_errors
    
    assert_equal "2005-12-25 to 2006-01-24",
      ChargePeriod.find( charge_periods(:january).id ).name
  end

  def test_update_locked
    # grab the charge period we're going to use twice
    period1 = charge_periods(:january)
    period2 = charge_periods(:february)
    
    # update it once, which should sucess
    post :update, :id => charge_periods(:january).id,
         :charge_period => { :name => "2006-03-25 to 2006-04-24",
                             :lock_version => period1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => charge_periods(:january).id,
         :charge_period => { :name => "name that shouldn't get updated", 
                             :lock_version => period2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "2006-03-25 to 2006-04-24", 
      ChargePeriod.find( charge_periods(:january).id ).name
  end

  def test_destroy
    assert_not_nil ChargePeriod.find( charge_periods(:february).id )

    post :destroy, :id => charge_periods(:february).id
    assert_response :redirect
    assert_redirected_to :controller => 'charge_sets', :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChargePeriod.find( charge_periods(:february).id )
    }
  end

  def test_destroy_with_associated_charge_sets
    assert_not_nil ChargePeriod.find( charge_periods(:january).id )

    post :destroy, :id => charge_periods(:january).id
    assert_response :redirect
    assert_redirected_to :controller => 'charge_sets', :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChargePeriod.find(1)
    }
  end
end
