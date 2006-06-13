require File.dirname(__FILE__) + '/../test_helper'
require 'chip_types_controller'

# Re-raise errors caught by the controller.
class ChipTypesController; def rescue_action(e) raise e end; end

class ChipTypesControllerTest < Test::Unit::TestCase
  fixtures :chip_types, :chip_transactions,
    :users, :roles, :permissions, :users_roles, :permissions_roles,
    :organisms

  def setup
    @controller = ChipTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # chip type management is only accessible to admins
    # so use that login for all tests
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

    assert_not_nil assigns(:chip_types)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:chip_type)
  end

  def test_create
    num_chip_types = ChipType.count

    post :create, :chip_type => {:name => "Chippy", :short_name => "chpy",
         :default_organism_id => "1"}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_chip_types + 1, ChipType.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:chip_type)
    assert assigns(:chip_type).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => 1
  end

  def test_destroy_no_associated_transactions
    assert_not_nil ChipType.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ChipType.find(1)
    }
  end
  
  def test_destroy_with_associated_transactions
    assert_not_nil ChipType.find(2)

    post :destroy, :id => 2
    assert_template "list"
    assert_flash_warning

    assert_not_nil ChipType.find(2)
  end
end
