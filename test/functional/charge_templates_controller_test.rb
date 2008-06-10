require File.dirname(__FILE__) + '/../test_helper'
require 'charge_templates_controller'

# Re-raise errors caught by the controller.
class ChargeTemplatesController; def rescue_action(e) raise e end; end

class ChargeTemplatesControllerTest < Test::Unit::TestCase
  fixtures :charge_templates

  def setup
    @controller = ChargeTemplatesController.new
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

    assert_not_nil assigns(:charge_templates)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:charge_template)
  end

  def test_create
    num_charge_templates = ChargeTemplate.count

    post :create, :charge_template => {:name => 'Blue Dye Label and Hyb',
                                       :chips_used => 1,
                                       :chip_cost => 0,
                                       :labeling_cost => 700,
                                       :hybridization_cost => 100,
                                       :qc_cost => 0,
                                       :other_cost => 0}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_charge_templates + 1, ChargeTemplate.count
  end

  def test_edit
    get :edit, :id => charge_templates(:labeling_and_hyb).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:charge_template)
    assert assigns(:charge_template).valid?
  end

  def test_update
    post :update, :id => charge_templates(:labeling_and_hyb).id
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked
    # grab the charge template we're going to use twice
    template1 = charge_templates(:labeling_and_hyb)
    template2 = charge_templates(:labeling_and_hyb)
    
    # update it once, which should sucess
    post :update, :id => charge_templates(:labeling_and_hyb).id, :charge_template => { :name => "template1", 
                                                :lock_version => template1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => charge_templates(:labeling_and_hyb).id, :charge_template => { :name => "template2", 
                                                :lock_version => template2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "template1",
      ChargeTemplate.find( charge_templates(:labeling_and_hyb).id ).name
  end

  def test_destroy
    assert_not_nil ChargeTemplate.find( charge_templates(:not_very_useful_template).id )

    post :destroy, :id => charge_templates(:not_very_useful_template).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChargeTemplate.find( charge_templates(:not_very_useful_template).id )
    }
  end
end
