require File.dirname(__FILE__) + '/../test_helper'
require 'quality_traces_controller'

# Re-raise errors caught by the controller.
class QualityTracesController; def rescue_action(e) raise e end; end

class QualityTracesControllerTest < Test::Unit::TestCase
  fixtures :quality_traces, :users

  def setup
    @controller = QualityTracesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show_as_admin
    login_as_admin
    
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:quality_trace)
    assert assigns(:quality_trace).valid?
  end

  def test_show_as_customer
    login_as_customer
    
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:quality_trace)
    assert assigns(:quality_trace).valid?
  end

end
