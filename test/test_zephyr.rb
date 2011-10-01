require 'helper'

class TestZephyr < Test::Unit::TestCase

  context "urls" do
    should "be canonicalized" do
      assert_equal 'http://example.com/', Zephyr.new('http://example.com').uri.to_s
      assert_equal 'http://example.com/', Zephyr.new('http://example.com/').uri.to_s
      assert_equal 'http://example.com/', Zephyr.new('http://example.com//').uri.to_s
    end
  end

  context "query string parameters" do
    should "be sorted" do 
      zephyr   = Zephyr.new
      duples   = ('a'..'z').zip('A'..'Z') # [ [ 'a', 'A' ], [ 'b', 'B' ], ... ]
      expected = duples.map { |l,u| '%s=%s' % [ l, u ] }.sort.join('&')

      assert_equal expected, zephyr.build_query_string(Hash[duples.shuffle])
    end

    should "be constructed for arrays" do
      zephyr = Zephyr.new
      assert_equal 'a=1&a=2', zephyr.build_query_string(:a => [ 2, 1 ])
    end
  end

  context "percent encoding" do
    should "be correct" do
      zephyr = Zephyr.new

      # RFC 3986 Reserved Characters
      assert_equal '%21', zephyr.percent_encode('!')
      assert_equal '%2A', zephyr.percent_encode('*')
      assert_equal '%27', zephyr.percent_encode("'")
      assert_equal '%28', zephyr.percent_encode('(')
      assert_equal '%29', zephyr.percent_encode(')')
      assert_equal '%3B', zephyr.percent_encode(';')
      assert_equal '%3A', zephyr.percent_encode(':')
      assert_equal '%40', zephyr.percent_encode('@')
      assert_equal '%26', zephyr.percent_encode('&')
      assert_equal '%3D', zephyr.percent_encode('=')
      assert_equal '%2B', zephyr.percent_encode('+')
      assert_equal '%24', zephyr.percent_encode('$')
      assert_equal '%2C', zephyr.percent_encode(',')
      assert_equal '%2F', zephyr.percent_encode('/')
      assert_equal '%3F', zephyr.percent_encode('?')
      assert_equal '%23', zephyr.percent_encode('#')
      assert_equal '%5B', zephyr.percent_encode('[')
      assert_equal '%5D', zephyr.percent_encode(']')

      # Common Percent Encodings
      assert_equal '%3C', zephyr.percent_encode('<')
      assert_equal '%3E', zephyr.percent_encode('>')
      assert_equal '%22', zephyr.percent_encode('"')
      assert_equal '%7B', zephyr.percent_encode('{')
      assert_equal '%7D', zephyr.percent_encode('}')
      assert_equal '%7C', zephyr.percent_encode('|')
      assert_equal '%5C', zephyr.percent_encode('\\')
      assert_equal '%60', zephyr.percent_encode('`')
      assert_equal '%5E', zephyr.percent_encode('^')
      assert_equal '%25', zephyr.percent_encode('%')
      assert_equal '%20', zephyr.percent_encode(' ')

      # Should test for \n as %0A or %0D or %0D%0A
      assert_contains ['%0A', '%0D', '%0D%0A'], zephyr.percent_encode("\n")

      # Should figure out why the will not be percent encoded by libcurl
      #assert_equal '%2E', zephyr.percent_encode('.')
      #assert_equal '%2D', zephyr.percent_encode('-')
      #assert_equal '%5F', zephyr.percent_encode('_')
      #assert_equal '%7E', zephyr.percent_encode('~')

      # Fancy
      assert_equal '%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8', zephyr.percent_encode('まつもと')
    end
  end
end
