require File.dirname(__FILE__) + '/../test_helper'

class ChargeTemplateTest < Test::Unit::TestCase
  fixtures :charge_templates

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ChargeTemplate, charge_templates(:first)
  end
end
