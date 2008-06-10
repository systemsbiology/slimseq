require File.dirname(__FILE__) + '/../test_helper'
require 'bioanalyzer_runs_controller'

# Re-raise errors caught by the controller.
class BioanalyzerRunsController; def rescue_action(e) raise e end; end

class BioanalyzerRunsControllerTest < Test::Unit::TestCase
  fixtures :bioanalyzer_runs, :quality_traces, :lab_groups, :lab_memberships,
           :users

  def setup
    @controller = BioanalyzerRunsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

#################################
#
# Run all tests as admin user
#
#################################

  def test_index_as_admin
    login_as_admin

    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list_as_admin
    login_as_admin

    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:bioanalyzer_runs)

    # admin should see both bioanalyzer runs in db
    assert_equal 2, assigns(:bioanalyzer_runs).size
  end

  def test_show_as_admin
    login_as_admin
  
    get :show, :id => bioanalyzer_runs(:bioanalyzer_run_00001).id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:quality_traces)
    
    # make sure 5 traces (4 samples + ladder) show up
    assert_equal 5, assigns(:quality_traces).size
  end

  def test_destroy_as_admin
    login_as_admin
  
    assert_not_nil BioanalyzerRun.find(bioanalyzer_runs(:bioanalyzer_run_00001).id)

    post :destroy, :id => bioanalyzer_runs(:bioanalyzer_run_00001).id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      BioanalyzerRun.find(1)
    }
  end

#################################
#
# Run all tests as customer user
#
#################################

  def test_index_as_customer
    login_as_customer

    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list_as_customer
    login_as_customer

    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:bioanalyzer_runs)

    # admin should see only his bioanalyzer run
    assert_equal 1, assigns(:bioanalyzer_runs).size
  end

  def test_show_as_customer
    login_as_customer
  
    get :show, :id => bioanalyzer_runs(:bioanalyzer_run_00002).id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:quality_traces)
    
    # make sure 13 traces (12 samples + ladder) show up
    assert_equal 13, assigns(:quality_traces).size
  end

  # customers should not be destroying bioanalyzer traces
  def test_destroy_as_customer
    login_as_customer
  
    assert_not_nil BioanalyzerRun.find(bioanalyzer_runs(:bioanalyzer_run_00001).id)

    post :destroy, :id => bioanalyzer_runs(:bioanalyzer_run_00001).id
    assert_response :redirect
    assert_redirected_to :controller => 'welcome'

    # make sure it didn't get destroyed
    assert_not_nil BioanalyzerRun.find(bioanalyzer_runs(:bioanalyzer_run_00001).id)
  end

end
