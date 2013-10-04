# encoding: utf-8
require 'helper'

class TestZephyr < Test::Unit::TestCase
  PARAMS = {  :method => :get, :timeout => 1000,
              :params => [{:query => ["test string", "again"]}] }

  TYPHOEUS_RESPONSE = Typhoeus::Response.new(
    :code => 200,
    :body => '',
    :request => Typhoeus::Request.new("http://www.example.com")
  )

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

    should "be present when POST and body is present" do
      z = Zephyr.new("http://www.example.com")
      Typhoeus::Request.expects(:run).with do |uri, params|
        params[:method] == :post && !params[:params] &&
          uri == 'http://www.example.com/users/1?something=true' &&
          params[:body] == 'body present'
      end.returns(TYPHOEUS_RESPONSE)
      z.post(200, 1, ["users", 1, {:something => 'true'}], 'body present')
    end

    should "use form data from path when POST and no body present" do
      z = Zephyr.new("http://www.example.com")
      Typhoeus::Request.expects(:run).with do |uri, params|
        params[:method] == :post &&
          params[:params] == {:something => 'true'}
          uri == 'http://www.example.com/users/1' &&
          !params[:body]
      end.returns(TYPHOEUS_RESPONSE)
      z.post(200, 1, ["users", 1, {:something => 'true'}], '')
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
    should "encode properly with Zephyr" do
      assert_equal '%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8', Typhoeus::Utils.escape('まつもと')
    end

    should "use Zephyr for escaping" do
      r = Typhoeus::Request.new("http://www.google.com", PARAMS)
      Zephyr.expects(:percent_encode).times(2)
      r.params_string
    end

    should "use Zephyr for building query string" do
      r = Typhoeus::Request.new("http://www.google.com", PARAMS)
      Zephyr.expects(:build_query_string).times(1)
      r.params_string
    end
  end

  should "support HTTP GET" do
    z = Zephyr.new("http://www.example.com")
    Typhoeus::Request.expects(:run).with do |uri, params|
      params[:method] == :get && uri == 'http://www.example.com/images/1'
    end.returns(TYPHOEUS_RESPONSE)
    z.get(200, 1, ["images", "1"])
  end

  should "support HTTP POST" do
    post_response = Typhoeus::Response.new(
      :code => 201,
      :body => '',
      :request => Typhoeus::Request.new("http://www.example.com")
    )

    z = Zephyr.new("http://www.example.com")
    Typhoeus::Request.expects(:run).with do |uri, params|
      params[:method] == :post &&
      params[:params] == {:name => 'Test User'} &&
      uri == 'http://www.example.com/users'
    end.returns(post_response)
    z.post(201, 1, ["users", {:name => 'Test User'}], '')
  end

  should "support HTTP PUT" do
    z = Zephyr.new("http://www.example.com")
    Typhoeus::Request.expects(:run).with do |uri, params|
      params[:method] == :put &&
      params[:params] == {:name => 'Test User'} &&
      uri == 'http://www.example.com/users/1'
    end.returns(TYPHOEUS_RESPONSE)
    z.put(200, 1, ["users", 1, {:name => 'Test User'}], '')
  end

  should "support HTTP DELETE" do
    delete_response = Typhoeus::Response.new(
      :code => 204,
      :body => '',
      :request => Typhoeus::Request.new("http://www.example.com")
    )

    z = Zephyr.new("http://www.example.com")
    Typhoeus::Request.expects(:run).with do |uri, params|
      params[:method] == :delete && uri == 'http://www.example.com/users/1'
    end.returns(delete_response)
    z.delete(204, 1, ["users", 1])
  end

  should "support custom HTTP methods" do
    z = Zephyr.new("http://www.example.com")
    Typhoeus::Request.expects(:run).with do |uri, params|
      params[:method] == :purge
    end.returns(TYPHOEUS_RESPONSE)
    z.custom(:purge, 200, 1, ["images", "4271e4c1594adc92651cf431029429d8"])
  end

  should 'support ssl certificates' do
    z = Zephyr.new('http://www.example.com')
    z.ssl(:ssl_cacert => 'ca_file.cer', :ssl_cert => 'acert.crt', :ssl_key => 'akey.key')

    Typhoeus::Request.expects(:run).with do |uri, params|
      params[:ssl_cacert] == 'ca_file.cer' &&
        params[:ssl_cert] == 'acert.crt' &&
        params[:ssl_key] == 'akey.key' && 
        params[:method] == :get &&
        uri == 'http://www.example.com/users/1'
    end.returns(TYPHOEUS_RESPONSE)

    z.get(200, 1, ['users', '1'])
  end
end
