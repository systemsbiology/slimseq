require File.dirname(__FILE__) + '/../test_helper'

class NamingElementTest < Test::Unit::TestCase
  fixtures :naming_schemes, :naming_elements, :naming_terms, :samples,
           :sample_terms, :sample_texts

  def test_destroy_warning_with_naming_terms
    expected_warning = "Destroying this naming element will also destroy:\n" + 
                       "2 naming term(s)\n" +
                       "0 sample text(s)\n" +
                       "Are you sure you want to destroy it?"
  
    element = NamingElement.find(2)   
    assert_equal expected_warning, element.destroy_warning
  end
  
  def test_destroy_warning_with_sample_texts
    expected_warning = "Destroying this naming element will also destroy:\n" + 
                       "0 naming term(s)\n" +
                       "1 sample text(s)\n" +
                       "Are you sure you want to destroy it?"
  
    element = NamingElement.find(5)   
    assert_equal expected_warning, element.destroy_warning
  end

  def test_free_text_conversion_from_free_text 
    element = naming_elements(:subject_number)
    
    element.update_attribute('free_text', false)
    element.free_text_conversion

    # make sure there is no longer a sample text
    # associated with this element
    assert_raise(ActiveRecord::RecordNotFound) {
      SampleText.find(1)
    }
    
    # check for existence of a naming_term for the previous sample text
    nt = NamingTerm.find(:first, :conditions => {
                                 :naming_element_id => element.id,
                                 :term => "32234",
                                 :abbreviated_term => "32234",
                                 :term_order => 0 })

    assert_not_nil nt
    
    # check for existence of a sample_term for the previous sample text
    assert_not_nil SampleTerm.find(:first, :conditions => {
                                   :sample_id => 6,
                                   :naming_term_id => nt.id,
                                   :term_order => 0 } )
  end

  def test_free_text_conversion_to_free_text 
    element = naming_elements(:replicate)  
    element.update_attribute('free_text', true)
    element.free_text_conversion

    # make sure there are no longer any naming terms
    # associated with this element
    [7, 8].each do |id|
      assert_raise(ActiveRecord::RecordNotFound) {
        NamingTerm.find(id)
      }
    end

    # make sure all the sample term associated with this element
    # is gone
    assert_raise(ActiveRecord::RecordNotFound) {
        SampleTerm.find(4)
    }
    
    # check for existence of sample_text for the previous sample term
    assert_not_nil SampleText.find(:first, :conditions => {
      :naming_element_id => element.id,
      :sample_id => 6,
      :text => 'B' } )
  end
end
