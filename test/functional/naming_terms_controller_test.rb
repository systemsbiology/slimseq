require File.dirname(__FILE__) + '/../test_helper'
require 'naming_terms_controller'

# Re-raise errors caught by the controller.
class NamingTermsController; def rescue_action(e) raise e end; end

class NamingTermsControllerTest < Test::Unit::TestCase
  fixtures :naming_schemes, :naming_elements, :naming_terms
  
  def setup
    @controller = NamingTermsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # test as admin
    login_as_admin
  end

  def test_list_for_naming_element
    get :list_for_naming_element, :id => 1

    assert_response :success
    assert_template 'list_for_naming_element'

    assert_not_nil assigns(:naming_terms)
  end

  def test_create
    num_naming_terms = NamingTerm.count

    post :create, :naming_term => {:term => "My Term",
                                   :naming_element_id => 1}

    assert_response :redirect
    assert_redirected_to :action => 'list_for_naming_element', :id => 1

    assert_equal num_naming_terms + 1, NamingTerm.count
    
    # make sure the correct term order is assigned
    new_term = NamingTerm.find(:first, :order => "id DESC")
    assert_equal 2, new_term.term_order
  end
  
  def test_update
    post :update, :id => 1

    assert_response :redirect
    assert_redirected_to :action => 'list_for_naming_element'
  end

  def test_move_up
    post :move_up, :id => 2

    assert_response :redirect
    assert_redirected_to :action => 'list_for_naming_element'
    
    down_term = NamingTerm.find(1)
    up_term = NamingTerm.find(2)

    assert_equal 1, down_term.term_order
    assert_equal 0, up_term.term_order
  end

  def test_move_down 
    post :move_down, :id => 1

    assert_response :redirect
    assert_redirected_to :action => 'list_for_naming_element'
    
    down_term = NamingTerm.find(1)
    up_term = NamingTerm.find(2)

    assert_equal 1, down_term.term_order
    assert_equal 0, up_term.term_order
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:naming_term)
    assert assigns(:naming_term).valid?

  end

  def test_destroy
    assert_not_nil NamingTerm.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list_for_naming_element'

    assert_raise(ActiveRecord::RecordNotFound) {
      NamingTerm.find(1)
    }
  end

end
