require File.dirname(__FILE__) + '/../test_helper'

class LabMembershipsControllerTest < ActionController::TestCase
  fixtures :users, :lab_memberships, :lab_groups
  
  def test_should_get_index
    get :index, :user_id => users(:customer_user).id
    assert_response :success
    assert_not_nil assigns(:lab_memberships)
  end

  def test_should_get_new
    get :new, :user_id => users(:customer_user).id
    assert_response :success
  end

  def test_should_create_lab_membership
    assert_difference('LabMembership.count') do
      post :create, :user_id => users(:customer_user).id,
        :lab_membership => { :user_id => users(:customer_user).id,
                             :lab_group_id => lab_groups(:monkey_group).id }
    end

    assert_redirected_to user_lab_memberships_path
  end

  def test_should_get_edit
    get :edit, :user_id => users(:customer_user).id,
      :id => lab_memberships(:customer_alligator).id
    assert_response :success
  end

  def test_should_update_lab_membership
    put :update, :user_id => users(:customer_user).id,
      :id => lab_memberships(:customer_alligator).id,
      :lab_membership => { :user_id => users(:customer_user).id,
                           :lab_group_id => lab_groups(:monkey_group).id }
    assert_redirected_to user_lab_memberships_path
  end

  def test_should_destroy_lab_membership
    assert_difference('LabMembership.count', -1) do
      delete :destroy, :user_id => users(:customer_user).id,
        :id => lab_memberships(:customer_alligator).id
    end

    assert_redirected_to user_lab_memberships_path
  end
end
