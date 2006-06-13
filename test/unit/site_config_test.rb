require File.dirname(__FILE__) + '/../test_helper'

class SiteConfigTest < Test::Unit::TestCase
  fixtures :site_configs

  # Replace this with your real tests.
  def test_truth
    assert_kind_of SiteConfig, site_configs(:first)
  end
end
