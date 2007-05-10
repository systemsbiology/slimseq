require 'scrubyt'
require 'test/unit'

class ConstraintTest < Test::Unit::TestCase

  def test_presence_of_attribute_constraints
    data = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'ruby_diamond').ensure_presence_of_attribute('color' => 'red').
                          ensure_absence_of_attribute('fill' => 'small_circles')      
    end
    
    assert_equal(data.children[0].constraints[0].type,
                 Scrubyt::Constraint::CONSTRAINT_TYPE_ENSURE_PRESENCE_OF_ATTRIBUTE)
    assert_equal(data.children[0].constraints[1].type,
                 Scrubyt::Constraint::CONSTRAINT_TYPE_ENSURE_ABSENCE_OF_ATTRIBUTE)
  end
  
  def test_presence_of_ancestor_node_constraints
    data = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'funky_rectangle').ensure_presence_of_ancestor_node(:contains, 'name' => 'crispy_ham').
                     ensure_absence_of_ancestor_node(:intersects_with, 'name' => 'spaghetti_ice')      
    end
  
    assert_equal(data.children[0].constraints[0].type,
                 Scrubyt::Constraint::CONSTRAINT_TYPE_ENSURE_PRESENCE_OF_ANCESTOR_NODE)
    assert_equal(data.children[0].constraints[1].type,
                 Scrubyt::Constraint::CONSTRAINT_TYPE_ENSURE_ABSENCE_OF_ANCESTOR_NODE)
  end
  
  def test_ancestor_node_constraints
    data0 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'funky_rectangle').ensure_presence_of_ancestor_node(:contains, 'name' => 'crispy_ham')                     
    end
    
    data1 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'funky_rectangle').ensure_presence_of_ancestor_node(:intersects_with, 'name' => 'spaghetti_ice')      
    end
    
    data2 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'ruby_diamond').ensure_presence_of_ancestor_node(:contains, 'name' => 'crispy_ham').
                     ensure_absence_of_ancestor_node(:intersects_with, 'name' => 'spaghetti_ice')      
    end
        
    data3 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
       
      shape 'line'#.ensure_presence_of_ancestor_node(:contains, 'name' => 'fungus_ooze').
                    # ensure_presence_of_ancestor_node(:intersects_with, 'object' => 'funky_lemon')
    end
    
    p data3.to_xml.to_s
    exit
    
    
    data4 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'ruby_diamond').ensure_presence_of_ancestor_node(:contains, 'name' => 'chunky_bacon').
                     ensure_absence_of_attribute 'thickness' => '2'
    end    
    
    assert_equal(data0.to_xml.to_s, "<root><shape>blue_circle</shape><shape>splatted_ellipse</shape></root>")
    assert_equal(data1.to_xml.to_s, "<root><shape>splatted_ellipse</shape></root>")
    assert_equal(data2.to_xml.to_s, "<root><shape>blue_circle</shape></root>")
    assert_equal(data3.to_xml.to_s, "<root><shape>big_rectangle</shape></root>")
    assert_equal(data4.to_xml.to_s, "<root><shape>ruby_diamond</shape></root>")
  end
  
  def test_attribute_constraints
    data0 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'ruby_diamond').ensure_presence_of_attribute 'color' => 'red'
    end

    data1 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      
      (shape 'ruby_diamond').ensure_presence_of_attribute 'color' => 'red', 'size' => '10x20'
    end
    
    data2 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      (shape 'ruby_diamond').ensure_presence_of_attribute 'color' => 'red', 'size' => nil
    end    

    data3 = Scrubyt::Extractor.define do
      fetch File.join(File.dirname(__FILE__), "input/constraint_test.html")
      (shape 'ruby_diamond').ensure_presence_of_attribute 'thickness' => nil
    end    
            
    assert_equal(data0.to_xml.to_s, "<root><shape>funky_rectangle</shape><shape>blue_circle</shape><shape>shiny_diamond</shape><shape>clunky_ellipse</shape><shape>twinky_line</shape></root>")
    assert_equal(data1.to_xml.to_s, "<root><shape>shiny_diamond</shape><shape>clunky_ellipse</shape></root>")
    assert_equal(data2.to_xml.to_s, "<root><shape>funky_rectangle</shape><shape>blue_circle</shape><shape>shiny_diamond</shape><shape>clunky_ellipse</shape></root>")
    assert_equal(data3.to_xml.to_s, "<root><shape>twinky_line</shape><shape>line</shape><shape>chunky_line</shape></root>")    
  end
end
