#require File.join(File.dirname(__FILE__), '../..', 'lib', 'filter')
require 'scrubyt'
require 'test/unit'

class FilterTest < Test::Unit::TestCase
  def test_determine_example_type
    #Test children example
    assert_equal(Scrubyt::BaseFilter.determine_example_type(nil), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_CHILDREN)                 
    #Test image example
    assert_equal(Scrubyt::BaseFilter.determine_example_type('scrubyt.png'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_IMAGE)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('scrubyt.gif'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_IMAGE)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('scrubyt.jpg'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_IMAGE)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('scrubyt.jpeg'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_IMAGE)                 
    assert_not_equal(Scrubyt::BaseFilter.determine_example_type('scrubyt.zip'), 
                     Scrubyt::BaseFilter::EXAMPLE_TYPE_IMAGE)
    assert_not_equal(Scrubyt::BaseFilter.determine_example_type('scrubyt.pif'), 
                     Scrubyt::BaseFilter::EXAMPLE_TYPE_IMAGE)
    #Test XPaths
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p/img'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)                 
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p/h3'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)                 
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p/h3/a/h2'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/h2'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/h1/h3'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)                                 
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('//p'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p//img'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('//p//img'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p[0]/img'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p[0]'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('//p[1]'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/p[1]//img[2]'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('//p[1]//img'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/table/tr/td//span/b'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('/table[0]//tr/td[1]/span[2]/b'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_not_equal(Scrubyt::BaseFilter.determine_example_type('table[0]//tr/td[1]/span[2]/b'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)                 
    assert_not_equal(Scrubyt::BaseFilter.determine_example_type('/table[a]//tr/td[1]/span[2]/b'),
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)                 
    assert_not_equal(Scrubyt::BaseFilter.determine_example_type('/tab2le[a]//tr/td[1]/span[2]/b'),
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    assert_not_equal(Scrubyt::BaseFilter.determine_example_type('/table[a]///tr/td[1]/span[2]/b'),
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_XPATH)
    #Test string example
    assert_equal(Scrubyt::BaseFilter.determine_example_type('Hello, world!'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_STRING)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('$1022'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_STRING)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('CANON'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_STRING)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('This is a string'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_STRING)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('45'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_STRING)
    assert_equal(Scrubyt::BaseFilter.determine_example_type('td'), 
                 Scrubyt::BaseFilter::EXAMPLE_TYPE_STRING)

  end
end
