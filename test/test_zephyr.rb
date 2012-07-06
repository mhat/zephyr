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
      duples   = ('a'..'z').zip('A'..'Z') # [ [ 'a', 'A' ], [ 'b', 'B' ], ... ]
      expected = duples.map { |l,u| '%s=%s' % [ l, u ] }.sort.join('&')

      assert_equal expected, Zephyr.build_query_string(Hash[duples.shuffle])
    end

    should "be constructed for arrays" do
      zephyr = Zephyr.new
      assert_equal 'a=1&a=2', Zephyr.build_query_string(:a => [ 2, 1 ])
    end
  end

  context "percent encoding" do
    should "be correct" do
      # RFC 3986 Reserved Characters
      assert_equal '%21', Zephyr.percent_encode('!')
      assert_equal '%2A', Zephyr.percent_encode('*')
      assert_equal '%27', Zephyr.percent_encode("'")
      assert_equal '%28', Zephyr.percent_encode('(')
      assert_equal '%29', Zephyr.percent_encode(')')
      assert_equal '%3B', Zephyr.percent_encode(';')
      assert_equal '%3A', Zephyr.percent_encode(':')
      assert_equal '%40', Zephyr.percent_encode('@')
      assert_equal '%26', Zephyr.percent_encode('&')
      assert_equal '%3D', Zephyr.percent_encode('=')
      assert_equal '%2B', Zephyr.percent_encode('+')
      assert_equal '%24', Zephyr.percent_encode('$')
      assert_equal '%2C', Zephyr.percent_encode(',')
      assert_equal '%2F', Zephyr.percent_encode('/')
      assert_equal '%3F', Zephyr.percent_encode('?')
      assert_equal '%23', Zephyr.percent_encode('#')
      assert_equal '%5B', Zephyr.percent_encode('[')
      assert_equal '%5D', Zephyr.percent_encode(']')

      # Common Percent Encodings
      assert_equal '%3C', Zephyr.percent_encode('<')
      assert_equal '%3E', Zephyr.percent_encode('>')
      assert_equal '%22', Zephyr.percent_encode('"')
      assert_equal '%7B', Zephyr.percent_encode('{')
      assert_equal '%7D', Zephyr.percent_encode('}')
      assert_equal '%7C', Zephyr.percent_encode('|')
      assert_equal '%5C', Zephyr.percent_encode('\\')
      assert_equal '%60', Zephyr.percent_encode('`')
      assert_equal '%5E', Zephyr.percent_encode('^')
      assert_equal '%25', Zephyr.percent_encode('%')
      assert_equal '%20', Zephyr.percent_encode(' ')

      # Should test for \n as %0A or %0D or %0D%0A
      assert_contains ['%0A', '%0D', '%0D%0A'], Zephyr.percent_encode("\n")

      # Should figure out why the will not be percent encoded by libcurl
      #assert_equal '%2E', zephyr.percent_encode('.')
      #assert_equal '%2D', zephyr.percent_encode('-')
      #assert_equal '%5F', zephyr.percent_encode('_')
      #assert_equal '%7E', zephyr.percent_encode('~')

      # Fancy
      assert_equal '%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8', Zephyr.percent_encode('まつもと')
    end
  end

  context "using Typhoeus extensions" do
    should "use Zephyr for escaping" do
      z = Zephyr.new("http://www.google.com")
      Zephyr.expects(:percent_encode).times(4)
      z.get(200, 1000, [{:query => ["test string", "again"]}])
    end

    should "use Zephyr for building query string" do
      z = Zephyr.new("http://www.google.com")
      Zephyr.expects(:build_query_string).times(1)
      z.get(200, 1000, [{:query => ["test string", "again"]}])
    end
  end
end
