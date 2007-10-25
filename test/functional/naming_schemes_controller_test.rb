require File.dirname(__FILE__) + '/../test_helper'
require 'naming_schemes_controller'

# Re-raise errors caught by the controller.
class NamingSchemesController; def rescue_action(e) raise e end; end

class NamingSchemesControllerTest < Test::Unit::TestCase
  fixtures :naming_schemes, :naming_elements, :naming_terms
  
  def setup
    @controller = NamingSchemesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # test as admin
    login_as_admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:naming_schemes)
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:naming_schemes)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:naming_scheme)
  end

  def test_create
    num_naming_schemes = NamingScheme.count

    post :create, :naming_scheme => {:name => "My Scheme"}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_naming_schemes + 1, NamingScheme.count
  end

  def test_rename
    get :rename, :id => 1

    assert_response :success
    assert_template 'rename'

    assert_not_nil assigns(:naming_scheme)
    assert assigns(:naming_scheme).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked
    # grab the chip_type we're going to use twice
    naming_scheme1 = NamingScheme.find(1)
    naming_scheme2 = NamingScheme.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :naming_scheme => { :name => "Updated Name 1", 
                                            :lock_version => naming_scheme1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :naming_scheme => { :name => "Updated Name 2", 
                                            :lock_version => naming_scheme2.lock_version }                                               

    assert_response :success                                                
    assert_template 'rename'
    assert_flash_warning
    
    assert_equal "Updated Name 1", NamingScheme.find(1).name
  end

  def test_destroy_no_associated_transactions
    assert_not_nil NamingScheme.find(1)

    post :destroy, :id => 2
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      NamingScheme.find(2)
    }
  end
  
  def test_destroy_with_associated_transactions
    assert_not_nil NamingScheme.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      NamingScheme.find(1)
    }
  end

end
