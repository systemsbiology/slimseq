require File.dirname(__FILE__) + '/../test_helper'
require 'organisms_controller'

# Re-raise errors caught by the controller.
class OrganismsController; def rescue_action(e) raise e end; end

class OrganismsControllerTest < Test::Unit::TestCase
  fixtures :organisms, :chip_types

  def setup
    @controller = OrganismsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # organism management is only accessible to admins
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

    assert_not_nil assigns(:organisms)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:organism)
  end

  def test_create
    num_organisms = Organism.count

    post :create, :organism => {:name => "Woolly Mammoth"}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_organisms + 1, Organism.count
  end

  def test_edit
    get :edit, :id => organisms(:first).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:organism)
    assert assigns(:organism).valid?
  end

  def test_update
    post :update, :id => organisms(:first).id
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => organisms(:first).id
  end

  def test_update_locked
    get :edit, :id => organisms(:first).id

    # grab the organism we're going to use twice
    organism1 = organisms(:first)
    organism2 = organisms(:first)
    
    # update it once, which should sucess
    post :update, :id => organisms(:first).id, :organism => { :name => "org1", 
                                            :lock_version => organism1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => organisms(:first).id, :organism => { :name => "org2", 
                                            :lock_version => organism2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "org1", Organism.find( organisms(:first).id ).name
  end

  def test_destroy
    assert_not_nil Organism.find( organisms(:weevil).id )

    post :destroy, :id => organisms(:weevil).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Organism.find( organisms(:weevil).id )
    }
  end
end
