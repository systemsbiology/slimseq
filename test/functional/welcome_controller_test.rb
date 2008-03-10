require File.dirname(__FILE__) + '/../test_helper'
require 'welcome_controller'

# Re-raise errors caught by the controller.
class WelcomeController; def rescue_action(e) raise e end; end

class WelcomeControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @controller = WelcomeController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
    
    # ensure there's no user at the start of each session
    @request.session[:user] = nil
  end

  def test_index_as_admin
    login_as_admin

    get :index
    
    assert_response :redirect
    assert_redirected_to 'welcome/staff'
  end

  def test_index_as_customer
    login_as_customer

    get :index
    
    assert_response :redirect
    # since welcome/home is the default home page, it shows up as ''
    assert_redirected_to ''
  end

  def test_staff_as_admin
    login_as_admin
    
    get :staff
    
    assert_response :success
    assert_template 'staff'
  end

  def test_home_as_customer
    login_as_customer
    
    get :home
    
    assert_response :success
    assert_template 'home'
  end
end
