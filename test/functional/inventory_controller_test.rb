require File.dirname(__FILE__) + '/../test_helper'
require 'inventory_controller'

# Re-raise errors caught by the controller.
class InventoryController; def rescue_action(e) raise e end; end

class InventoryControllerTest < Test::Unit::TestCase
  fixtures :users

  def setup
    @controller = InventoryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index_as_admin
    login_as_admin
    
    get :index
    
    assert_response :success
    assert_template 'index'
    
    assert_not_nil assigns(:lab_groups)
  end

  def test_index_as_customer
    login_as_admin
    
    get :index
    
    assert_response :success
    assert_template 'index'
    
    assert_not_nil assigns(:lab_groups)
  end
end
