require File.dirname(__FILE__) + '/../test_helper'
require 'site_config_controller'

# Re-raise errors caught by the controller.
class SiteConfigController; def rescue_action(e) raise e end; end

class SiteConfigControllerTest < Test::Unit::TestCase
  def setup
    @controller = SiteConfigController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
