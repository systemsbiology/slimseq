require 'scrubyt'
require 'test/unit'

class ExtractorTest < Test::Unit::TestCase
  def test_create_one_pattern
    pattern = Scrubyt::Extractor.define do 
      fetch File.join(File.dirname(__FILE__), "input/test.html")
      pattern "1"
    end
    assert_instance_of(Scrubyt::Pattern, pattern)
    
    assert_equal(pattern.name, "root")
    assert_equal(pattern.children[0].name, 'pattern')
    assert_equal(pattern.type, :root)
    assert_equal(pattern.output_type, :model)
    
    assert_equal(pattern.generalize, false)
    assert_equal(pattern.children[0].generalize, true)
  end

  def test_create_child_pattern
    pattern = Scrubyt::Extractor.define do 
      fetch File.join(File.dirname(__FILE__), "input/test.html")
      parent { child "2" }
    end
      
    assert_equal(pattern.name, "root")
    assert_equal(pattern.type, :root)
    assert_equal(pattern.output_type, :model)
    
    assert_equal(pattern.children[0].name, "parent")        
    assert_equal(pattern.children[0].type, :tree)
    assert_equal(pattern.children[0].output_type, :model)
  end

  def test_create_more_children
    pattern = Scrubyt::Extractor.define do 
      fetch File.join(File.dirname(__FILE__), "input/test.html")
      parent do
        child1 '1'
        child2 '2'
        child3 '3'
        child4 '4'
      end
    end
    
    assert_equal(pattern.children[0].children.size, 4)
    
    i = 0    
    3.times do
      assert_equal(pattern.children[0].children[i].parent, 
                   pattern.children[0].children[i+=1].parent) 
      assert_equal(pattern.children[0].children[i].children, [])
    end
    assert_equal(pattern.children[0].children[3].parent, pattern.children[0])
    assert_equal(pattern.children[0].children[3].parent.parent, pattern)
  end

  def test_create_hierarchy
    tree = Scrubyt::Extractor.define do 
      fetch File.join(File.dirname(__FILE__), "input/test.html")
      a { b { c { d { e "1" } } } }
    end
    
    assert_equal(tree.name,"root")
    assert_equal(tree.children[0].name,"a")
    assert_equal(tree.children[0].children[0].name,"b")
    assert_equal(tree.children[0].children[0].children[0].name,"c")
    assert_equal(tree.children[0].children[0].children[0].children[0].name,"d")    
  end
  

  def test_empty_filter
    tree = Scrubyt::Extractor.define do 
      fetch File.join(File.dirname(__FILE__), "input/test.html")      
      a do
        b '1'
        c '2'
      end
    end
    
    assert_not_nil(tree.filters[0])
    assert_nil(tree.example)
    assert_not_nil(tree.children[0].filters[0])
    assert_nil(tree.children[0].example)
    assert_not_nil(tree.children[0].children[0].filters[0])
    assert_equal(tree.children[0].children[0].filters[0].example,'1')
    assert_not_nil(tree.children[0].children[1].filters[0])
    assert_equal(tree.children[0].children[1].filters[0].example,'2')
  end  
end
