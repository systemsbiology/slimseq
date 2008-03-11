$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class LinksMechTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_find_meta
    page = @agent.get("http://localhost:#{PORT}/find_link.html")
    assert_equal(2, page.meta.length)
    assert_equal("http://www.drphil.com/", page.meta[0].href.downcase)
    assert_equal("http://www.upcase.com/", page.meta[1].href.downcase)
  end

  def test_find_link
    page = @agent.get("http://localhost:#{PORT}/find_link.html")
    assert_equal(15, page.links.length)
  end

  def test_alt_text
    page = @agent.get("http://localhost:#{PORT}/alt_text.html")
    assert_equal(5, page.links.length)
    assert_equal(1, page.meta.length)

    assert_equal('', page.meta.first.text)
    assert_equal('alt text', page.links.href('alt_text.html').first.text)
    assert_equal('', page.links.href('no_alt_text.html').first.text)
    assert_equal('no image', page.links.href('no_image.html').first.text)
    assert_equal('', page.links.href('no_text.html').first.text)
    assert_equal('', page.links.href('nil_alt_text.html').first.text)
  end

  def test_click_link
    @agent.user_agent_alias = 'Mac Safari'
    page = @agent.get("http://localhost:#{PORT}/frame_test.html")
    link = page.links.text("Form Test")
    assert_not_nil(link)
    assert_equal('Form Test', link.text)
    page = @agent.click(link)
    assert_equal("http://localhost:#{PORT}/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_method
    page = @agent.get("http://localhost:#{PORT}/frame_test.html")
    link = page.links.text("Form Test")
    assert_not_nil(link)
    assert_equal('Form Test', link.text)
    page = link.click
    assert_equal("http://localhost:#{PORT}/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_find_bold_link
    page = @agent.get("http://localhost:#{PORT}/tc_links.html")
    link = page.links.text(/Bold Dude/)
    assert_equal(1, link.length)
    assert_equal('Bold Dude', link.first.text)

    link = page.links.text('Aaron James Patterson')
    assert_equal(1, link.length)
    assert_equal('Aaron James Patterson', link.first.text)

    link = page.links.text('Aaron Patterson')
    assert_equal(1, link.length)
    assert_equal('Aaron Patterson', link.first.text)

    link = page.links.text('Ruby Rocks!')
    assert_equal(1, link.length)
    assert_equal('Ruby Rocks!', link.first.text)
  end

  def test_link_with_encoded_space
    page = @agent.get("http://localhost:#{PORT}/tc_links.html")
    link = page.links.text('encoded space').first
    page = @agent.click link
  end

  def test_link_with_space
    page = @agent.get("http://localhost:#{PORT}/tc_links.html")
    link = page.links.text('not encoded space').first
    page = @agent.click link
  end
end
