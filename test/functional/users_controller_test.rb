require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  fixtures :users

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_not_require_password_on_signup
    assert_difference 'User.count' do
      create_user(:password => nil, :password_confirmation => nil)
      assert assigns(:user)
      assert_response :redirect
    end
  end

  def test_should_not_require_password_confirmation_on_signup_without_password
    assert_difference 'User.count' do
      create_user(:password => nil, :password_confirmation => nil)
      assert assigns(:user)
      assert_response :redirect
    end
  end
  
  def test_should_require_password_confirmation_on_signup_with_password
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'User.count' do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  def test_should_get_index_as_admin
    login_as_admin

    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_should_get_edit_as_admin
    login_as_admin
    
    get :edit, :id => users(:admin_user).id
    assert_response :success
  end

  def test_should_update_user
    login_as_admin
    
    put :update, :id => users(:admin_user).id, :user => { :firstname => 'Bob' }
    assert_redirected_to users_path
  end

  def test_should_destroy_user
    login_as_admin
    
    assert_difference('User.count', -1) do
      delete :destroy, :id => users(:admin_user).id
    end
  end
  
  protected
    def create_user(options = {})
      post :create, :user => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire', :password_confirmation => 'quire',
        :firstname => 'quentin', :lastname => 'quire' }.merge(options)
    end
end
