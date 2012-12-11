# encoding: utf-8
require 'helper'

class TestResponse < Test::Unit::TestCase
  def setup
    @response = Typhoeus::Response.new
    @response.stubs(:timed_out?).returns(false)
  end

  should 'not be retryable if successful' do
    assert !@response.retryable_request?
  end

  should 'be retryable when timed out' do
    @response.stubs(:timed_out?).returns(true)
    assert @response.retryable_request?
  end

  should 'be retryable when the response code is a server error' do
    @response.stubs(:code).returns(500)
    assert @response.retryable_request?
  end

  should 'be retryable when the connection failed' do
    @response.stubs(:curl_return_code).returns(7)
    assert @response.retryable_request?
  end
end
