require File.dirname(__FILE__) + '/../test_helper'
require 'site_config_controller'

# Re-raise errors caught by the controller.
class SiteConfigController; def rescue_action(e) raise e end; end

class SiteConfigControllerTest < Test::Unit::TestCase
  def setup
    @controller = SiteConfigController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # test with admin login
    login_as_admin
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'edit'
  end

  def test_update_locked
    # grab the site_config we're going to use twice
    site_config1 = SiteConfig.find(1)
    site_config2 = SiteConfig.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :site_config => { :organization_name => "lab1", 
                                            :lock_version => site_config1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :site_config => { :organization_name => "lab2", 
                                            :lock_version => site_config2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "lab1", SiteConfig.find(1).organization_name
  end
end
