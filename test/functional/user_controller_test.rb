require File.dirname(__FILE__) + '/../test_helper'
require 'user_controller'

# Re-raise errors caught by the controller.
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  fixture :users, :table_name => LoginEngine.config(:user_table), :class_name => 'User'
  fixture :users_roles, :table_name => UserEngine.config(:user_role_table)
  fixture :roles, :table_name => UserEngine.config(:role_table), :class_name => 'Role'
  fixture :permissions_roles, :table_name => UserEngine.config(:permission_role_table)
  fixture :permissions, :table_name => UserEngine.config(:permission_table), :class_name => 'Permission'
           
  def setup
    @controller = UserController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
    # ensure there's no use in each session
    @request.session[:user] = nil
  end

  def test_index_as_admin
    # had to set session user this way, since it didn't work
    # via post :login within this test (although it works everywhere else)
    @request.session[:user] = users(:admin_user)

    get :index
    
    assert_response :redirect
    assert_redirected_to 'user/staff'
  end

  def test_index_as_customer
    @request.session[:user] = users(:customer_user)

    get :index
    
    assert_response :redirect
    # since user/home is the default home page, it shows up as ''
    assert_redirected_to ''
  end

  def test_staff_as_admin
    @request.session[:user] = users(:admin_user)
    get :staff
    
    assert_response :success
    assert_template 'staff'
  end

  def test_home_as_customer
    @request.session[:user] = users(:customer_user)
    
    get :home
    
    assert_response :success
    assert_template 'home'
  end

# Can't get this to work--complains that 'show' method in
# UserController can't find 'find_user' method, which is in
# the User Engine UserController
#  def test_show_user
#    @request.session[:user] = users(:admin_user)
#    
#    get :show, :id => users(:customer_user).id
#    assert_response :success
#    
#    get :show, :id => 1231651161
#    assert_redirected_to :action => 'list'
#    assert_match /There is no user with ID/, flash[:message]    
#  
#    get :show
#    assert_redirected_to :action => 'list'
#    assert_match /There is no user with ID/, flash[:message]
#  end  

  def test_select_naming_scheme_as_admin
    @request.session[:user] = users(:admin_user)

    get :staff
    assert_response :success
    assert_template 'staff'

    post :select_naming_scheme, :user => { :current_naming_scheme_id => 1 }
    assert_response :redirect
    assert_redirected_to 'user/home'
    
    assert_equal 1, User.find(1).current_naming_scheme_id
  end

  def test_select_naming_scheme_as_customer
    @request.session[:user] = users(:customer_user)

    get :home
    assert_response :success
    assert_template 'home'

    post :select_naming_scheme, :user => { :current_naming_scheme_id => 1 }
    assert_response :redirect
    assert_redirected_to 'user/home'
    
    assert_equal 1, User.find(2).current_naming_scheme_id
  end 
  
end
