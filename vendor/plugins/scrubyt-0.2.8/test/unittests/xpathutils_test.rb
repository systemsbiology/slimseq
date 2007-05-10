#require File.join(File.dirname(__FILE__), '../../lib', 'xpathutils')
require 'scrubyt'
require 'test/unit'

class XPathUtilsTest < Test::Unit::TestCase

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
    
  def test_lowest_common_ancestor        
    lca_b_g = Scrubyt::XPathUtils.lowest_common_ancestor(@b,@g)
    lca_f_d = Scrubyt::XPathUtils.lowest_common_ancestor(@f,@d)
    lca_f_g = Scrubyt::XPathUtils.lowest_common_ancestor(@f,@g)
    lca_f_f = Scrubyt::XPathUtils.lowest_common_ancestor(@f,@f)
    lca_f_k = Scrubyt::XPathUtils.lowest_common_ancestor(@f,@k)
    lca_a_g = Scrubyt::XPathUtils.lowest_common_ancestor(@a,@g)
    lca_q_r = Scrubyt::XPathUtils.lowest_common_ancestor(@q,@r)
    lca_m_r = Scrubyt::XPathUtils.lowest_common_ancestor(@m,@r)    
    lca_n1_e = Scrubyt::XPathUtils.lowest_common_ancestor(@n_1,@e)
    lca_r_b =  Scrubyt::XPathUtils.lowest_common_ancestor(@r,@b)
    lca_a_a =  Scrubyt::XPathUtils.lowest_common_ancestor(@a,@a)
    
    assert_equal(lca_b_g, @a)
    assert_equal(lca_f_d, @b)
    assert_equal(lca_f_g, @a)
    assert_equal(lca_f_f, @e)
    assert_equal(lca_f_k, @e)    
    assert_equal(lca_q_r, @n_3)
    assert_equal(lca_m_r, @e)
    assert_equal(lca_n1_e, @e)
    assert_equal(lca_a_g, @a)  
    assert_equal(lca_a_a, @doc1)
    assert_equal(lca_r_b, @b)
  end
  
  def test_find_index
    assert_equal(Scrubyt::XPathUtils.find_index(@a), 1)
    assert_equal(Scrubyt::XPathUtils.find_index(@b), 1)
    assert_equal(Scrubyt::XPathUtils.find_index(@c), 1)
    assert_equal(Scrubyt::XPathUtils.find_index(@d), 1)    
    assert_equal(Scrubyt::XPathUtils.find_index(@n_1), 1)
    assert_equal(Scrubyt::XPathUtils.find_index(@n_2), 2)
    assert_equal(Scrubyt::XPathUtils.find_index(@n_3), 3)
    assert_equal(Scrubyt::XPathUtils.find_index(@n_4), 4)
    assert_equal(Scrubyt::XPathUtils.find_index(@r), 1)
  end
  
  def test_generate_XPath
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@a), "/a")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@b), "/a/b")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@c), "/a/b/c")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@d), "/a/b/d")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@e), "/a/b/e")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@f), "/a/b/e/f")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_1), "/a/b/e/n")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_2), "/a/b/e/n")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_3), "/a/b/e/n")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_4), "/a/b/e/n")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@r), "/a/b/e/n/r")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@g), "/a/g")    
  end
  
  def test_generate_XPath_with_indices
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@a, nil, true), "/a[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@b, nil, true), "/a[1]/b[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@c, nil, true), "/a[1]/b[1]/c[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@d, nil, true), "/a[1]/b[1]/d[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@e, nil, true), "/a[1]/b[1]/e[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@f, nil, true), "/a[1]/b[1]/e[1]/f[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_1, nil, true), "/a[1]/b[1]/e[1]/n[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_2, nil, true), "/a[1]/b[1]/e[1]/n[2]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_3, nil, true), "/a[1]/b[1]/e[1]/n[3]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@n_4, nil, true), "/a[1]/b[1]/e[1]/n[4]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@p, nil, true), "/a[1]/b[1]/e[1]/p[1]")
    assert_equal(Scrubyt::XPathUtils.generate_XPath(@r, nil, true), "/a[1]/b[1]/e[1]/n[3]/r[1]")
  end
  
  def test_generate_relative_XPath
    assert_nil(Scrubyt::XPathUtils.generate_relative_XPath(@a,@a))
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@b, @a), "/b[1]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@c, @a), "/b[1]/c[1]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@d, @a), "/b[1]/d[1]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@f, @a), "/b[1]/e[1]/f[1]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@n_1, @a), "/b[1]/e[1]/n[1]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@n_2, @a), "/b[1]/e[1]/n[2]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@n_3, @a), "/b[1]/e[1]/n[3]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@n_4, @a), "/b[1]/e[1]/n[4]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@r, @b), "/e[1]/n[3]/r[1]")
    assert_equal(Scrubyt::XPathUtils.generate_relative_XPath(@q, @e), "/n[3]/q[1]")
    
    assert_nil(Scrubyt::XPathUtils.generate_relative_XPath(@r, @n_2))
    assert_nil(Scrubyt::XPathUtils.generate_relative_XPath(@q, @g))
    assert_nil(Scrubyt::XPathUtils.generate_relative_XPath(@n_3, @n_2))    
  end
  
  def test_generate_generalized_relative_XPath
    assert_nil(Scrubyt::XPathUtils.generate_generalized_relative_XPath(@b,@b))
    assert_equal(Scrubyt::XPathUtils.generate_generalized_relative_XPath(@b, @a), "/b")
    assert_equal(Scrubyt::XPathUtils.generate_generalized_relative_XPath(@f, @a), "/b/e/f")
    assert_equal(Scrubyt::XPathUtils.generate_generalized_relative_XPath(@r, @n_3), "/r")
    
    assert_nil(Scrubyt::XPathUtils.generate_generalized_relative_XPath(@r, @n_2))
  end
  
end
