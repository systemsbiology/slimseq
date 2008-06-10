require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < Test::Unit::TestCase
  fixtures :projects, :lab_groups

  def setup
    @controller = ProjectsController.new
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

    assert_not_nil assigns(:projects)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:project)
  end

  def test_create
    num_projects = Project.count

    post :create, :project => {:name => "The Best Project",
                               :budget => "12345678",
                               :lab_group_id => lab_groups(:gorilla_group)}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_projects + 1, Project.count
  end

  def test_edit
    get :edit, :id => projects(:first).id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:project)
    assert assigns(:project).valid?
  end

  def test_update
    post :update, :id => projects(:first).id
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => projects(:first).id
  end

  def test_update_locked
    # grab the project we're going to use twice
    project1 = Project.find( projects(:first).id )
    project2 = Project.find( projects(:first).id )
    
    # update it once, which should sucess
    post :update, :id => projects(:first).id, :project => { :name => "project1", 
                                            :lock_version => project1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => projects(:first).id, :project => { :name => "project2", 
                                            :lock_version => project2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "project1", Project.find( projects(:first).id ).name
  end

  def test_destroy_no_associated_transactions
    assert_not_nil Project.find( projects(:another).id )

    post :destroy, :id => projects(:another).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Project.find( projects(:another).id )
    }
  end
  
  def test_destroy_with_associated_transactions
    assert_not_nil Project.find( projects(:first).id )

    post :destroy, :id => projects(:first).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Project.find( projects(:first).id )
    }
  end
end
