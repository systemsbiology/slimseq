require 'scrubyt'
require 'test/unit'

class SimpleExampleLookupTest

  def setup
    doc1 = <<-DOC
    <a>
        <b>
                <c/>
                <d>dddd</d>
                <e>
                    <f>fff</f>
                    <k>kk</k>
                    <j/>
                    <l>lll</l>
                    <m/>
                    <n>nnn</n>
                    <n>nnnnnn</n>
                    <n>
                        nnnnnnnnn
                        <q/>
                        <r>rrr</r>
                    </n>
                    <o>ooo</o>
                    <n>nnnnnnnnnnnn</n>
                    <p>ppp</p>
                </e>
        </b>
        <g>ggg</g>
    </a>
    DOC
    @doc1 = Hpricot(doc1)
    @a = @doc1.children[1]
    @b = @a.children[1]
    @c = @b.children[1]
    @d = @b.children[3]
    @e = @b.children[5]
    @f = @e.children[1]
    @g = @a.children[@a.children.size-2]
    @k = @e.children[3]
    @j = @e.children[5]
    @l = @e.children[7]
    @m = @e.children[9]
    @n_1 = @e.children[11]
    @n_2 = @e.children[13]
    @n_3 = @e.children[15]
    @o = @e.children[17]        
    @n_4 = @e.children[19]    
    @p = @e.children[21]
    @q = @n_3.children[1]
    @r = @n_3.children[3]
    #@doc2 = Hpricot(open(File.join(File.dirname(__FILE__), "test.html")))
  end
  
  def test_find_node_from_text
    elem = Scrubyt::XPathUtils.find_node_from_text(@doc1,"fff", false)
    assert_instance_of(Hpricot::Elem, elem)
    assert_equal(elem, @f)
    
    elem = Scrubyt::XPathUtils.find_node_from_text(@doc1,"dddd", false)
    assert_equal(elem, @d)
    
    elem = Scrubyt::XPathUtils.find_node_from_text(@doc1,"rrr", false)
    assert_equal(elem, @r)
    
  end
end
