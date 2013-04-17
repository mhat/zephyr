require 'logger'
require 'net/http'
require 'typhoeus'
require 'typhoeus_ext/request.rb'
require 'typhoeus_ext/response.rb'
require 'typhoeus_ext/utils.rb'
require 'yajl'

# Stolen with a fair bit of modification from the riak-client gem, which is
# Copyright 2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# Splits headers into < 8KB chunks
# @private
module Net
  module HTTPHeader
    def each_capitalized
      # 1.9 check
      respond_to?(:enum_for) and (block_given? or return enum_for(__method__))
      @header.each do |k,v|
        base_length = "#{k}: \r\n".length
        values = v.map { |i| i.to_s.split(', ') }.flatten
        while !values.empty?
          current_line = ""
          while values.first && current_line.length + base_length + values.first.length + 2 < 8192
            val = values.shift.strip
            current_line += current_line.empty? ? val : ", #{val}"
          end
          yield capitalize(k), current_line
        end
      end
    end
  end
end

# A simple front-end for doing HTTP requests quickly and simply.
class Zephyr
  autoload :FailedRequest, "zephyr/failed_request"

  def initialize(root_uri = '')
    @root_uri = URI.parse(root_uri.to_s).freeze
  end

  def default_headers
    {
      'Accept'      => 'application/json;q=0.7, */*;q=0.5',
      'User-Agent'  => 'zephyr',
    }
  end

  class << self
    @debug_mode = false

    def logger
      @@logger
    end

    def logger=(logger)
      @@logger = logger
    end

    def debug_mode
      @debug_mode
    end

    def debug_mode=(mode)
      @debug_mode = mode
    end

    def percent_encode(value)
      Typhoeus::Curl.easy_escape(typhoeus_easy.handle, value.to_s, value.to_s.bytesize)
    end

    def build_query_string(params)
      params.map do |k, v|
        if v.kind_of? Array
          build_query_string(v.map { |x| [k, x] })
        else
          "#{percent_encode(k)}=#{percent_encode(v)}"
        end
      end.sort.join '&'
    end

  private

    # NOTE: This is here only because it provides a binding to
    # Curb's 'easy_escape' function, which does what we want.
    # Don't use it to perform requests. Ever.
    #
    def typhoeus_easy
      @_typhoeus_easy ||= Typhoeus::Easy.new.freeze
    end
  end

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::Severity::WARN

  # Performs a HEAD request to the specified resource.
  #
  # A request to /users/#{@user.id}/things?q=woof with an Accept header of
  # "text/plain" which is expecting a 200 OK within 50ms
  #
  #   http.head(200, 50, ["users", @user.id, "things", {"q" => "woof"}], "Accept" => "text/plain")
  #
  # This returns a hash with three keys:
  #   :status       The numeric HTTP status code
  #   :body         The body of the response entity, if any
  #   :headers      A hash of header values
  def head(expected_statuses, timeout, path_components, headers={})
    headers = default_headers.merge(headers)
    verify_path!(path_components)
    perform(:head, path_components, headers, expected_statuses, timeout)
  end

  # Performs a GET request to the specified resource.
  #
  # A request to /users/#{@user.id}/things?q=woof with an Accept header of
  # "text/plain" which is expecting a 200 OK within 50ms
  #
  #   http.get(200, 50 ["users", @user.id, "things", {"q" => "woof"}], "Accept" => "text/plain")
  #
  # This returns a hash with three keys:
  #   :status       The numeric HTTP status code
  #   :body         The body of the response entity, if any
  #   :headers      A hash of header values
  def get(expected_statuses, timeout, path_components, headers={})
    headers   = default_headers.merge(headers)
    verify_path!(path_components)
    perform(:get, path_components, headers, expected_statuses, timeout)
  end

  # The same thing as #get, but decodes the response entity as JSON (if it's
  # application/json) and adds it under the :json key in the returned hash.
  def get_json(expected_statuses, timeout, path_components, headers={}, yajl_opts={})
    response = get(expected_statuses, timeout, path_components, headers)
    create_json_response(response, yajl_opts)
  end

  # Performs a PUT request to the specified resource.
  #
  # A request to /users/#{@user.id}/things?q=woof with an Content-Type header of
  # "text/plain" and a request entity of "yay" which is expecting a 204 No
  # Content within 1000ms
  #
  #   http.put(204, 1000, ["users", @user.id, "things", {"q" => "woof"}], "yay", "Content-Type" => "text/plain")
  #
  # This returns a hash with three keys:
  #   :status       The numeric HTTP status code
  #   :body         The body of the response entity, if any
  #   :headers      A hash of header values
  def put(expected_statuses, timeout, path_components, entity, headers={})
    headers = default_headers.merge(headers)
    verify_path_and_entity!(path_components, entity)
    perform(:put, path_components, headers, expected_statuses, timeout, entity)
  end

  # The same thing as #put, but encodes the entity as JSON and specifies
  # "application/json" as the request entity content type.
  def put_json(expected_statuses, timeout, path_components, entity, headers={})
    response = put(expected_statuses, timeout, path_components, Yajl::Encoder.encode(entity), headers.merge("Content-Type" => "application/json"))
    create_json_response(response)
  end

  # Performs a POST request to the specified resource.
  #
  # A request to /users/#{@user.id}/things?q=woof with an Content-Type header of
  # "text/plain" and a request entity of "yay" which is expecting a 201 Created
  # within 500ms
  #
  #   http.post(201, 500, ["users", @user.id, "things", {"q" => "woof"}], "yay", "Content-Type" => "text/plain")
  #
  # This returns a hash with three keys:
  #   :status       The numeric HTTP status code
  #   :body         The body of the response entity, if any
  #   :headers      A hash of header values
  def post(expected_statuses, timeout, path_components, entity, headers={})
    headers   = default_headers.merge(headers)
    verify_path_and_entity!(path_components, entity)
    perform(:post, path_components, headers, expected_statuses, timeout, entity)
  end

  # The same thing as #post, but encodes the entity as JSON and specifies
  # "application/json" as the request entity content type.
  def post_json(expected_statuses, timeout, path_components, entity, headers={})
    response = post(
                    expected_statuses,
                    timeout,
                    path_components,
                    Yajl::Encoder.encode(entity),
                    headers.merge("Content-Type" => "application/json")
                   )
    create_json_response(response)
  end

  # Performs a DELETE request to the specified resource.
  #
  # A request to /users/#{@user.id}/things?q=woof which is expecting a 204 No
  # Content within 666ms
  #
  #   http.put(200, 666, ["users", @user.id, "things", {"q" => "woof"}])
  #
  # This returns a hash with three keys:
  #   :status       The numeric HTTP status code
  #   :body         The body of the response entity, if any
  #   :headers      A hash of header values
  def delete(expected_statuses, timeout, path_components, headers={})
    headers = default_headers.merge(headers)
    verify_path!(path_components)
    perform(:delete, path_components, headers, expected_statuses, timeout)
  end

  # Performs a custom HTTP method request to the specified resource.
  #
  # A PURGE request to /users/#{@user.id} which is expecting a 200 OK within 666ms
  #
  #   http.custom(:purge, 200, 666, ["users", @user.id])
  #
  # This returns a hash with three keys:
  #   :status       The numeric HTTP status code
  #   :body         The body of the response entity, if any
  #   :headers      A hash of header values
  def custom(method, expected_statuses, timeout, path_components, headers={})
    headers = default_headers.merge(headers)
    verify_path!(path_components)
    perform(method, path_components, headers, expected_statuses, timeout)
  end

  # Creates a URI object, combining the root_uri passed on initialization
  # with the given parts.
  #
  # Example:
  #
  #   http = Zephyr.new 'http://host/'
  #   http.uri(['hi', 'bob', {:foo => 'bar'}]) => http://host/hi/bob?foo=bar
  #
  def uri(given_parts = [])
    @root_uri.dup.tap do |uri|
      parts     = given_parts.dup.unshift(uri.path) # URI#merge is broken.
      uri.query = Zephyr.build_query_string(parts.pop) if parts.last.is_a? Hash
      uri.path  = ('/%s' % parts.join('/')).gsub(/\/+/, '/')
    end
  end

  # Comes handy in IRB
  #
  def inspect
    '#<%s:0x%s root_uri=%s>' % [ self.class.to_s, object_id.to_s(16), uri.to_s ]
  end

  def cleanup!
    Typheous::Hydra.hydra.cleanup
  end

  def verify_path_and_entity!(path_components, entity)
    begin
      verify_path!(path_components)
    rescue ArgumentError
      raise ArgumentError, "You must supply both a resource path and a body."
    end

    raise ArgumentError, "Request body must be a string or IO." unless String === entity || IO === entity
  end

  def verify_path!(path_components)
    path_components = Array(path_components).flatten
    raise ArgumentError, "Resource path too short" unless path_components.length > 0
  end

  def valid_response?(expected, actual)
    Array(expected).map { |code| code.to_i }.include?(actual.to_i)
  end

  def return_body?(method, code)
    method != :head && !valid_response?([204,205,304], code)
  end

  def perform(method, path_components, headers, expect, timeout, data=nil)
    params           = {}
    params[:headers] = headers
    params[:timeout] = timeout
    params[:follow_location] = false

    if path_components.last.is_a?(Hash) && (!data || data.empty?)
      params[:params]  = path_components.pop
    end

    params[:method]  = method

    # seriously, why is this on by default
    Typhoeus::Hydra.hydra.disable_memoization

    # if you want debugging
    params[:verbose] = Zephyr.debug_mode

    # have a vague feeling this isn't going to work as expected
    if method == :post || method == :put
      data = data.read if data.respond_to?(:read)
      params[:body] = data if data != ''
    end

    http_start = Time.now.to_f
    response   = Typhoeus::Request.run(uri(path_components).to_s, params)
    http_end   = Time.now.to_f

    Zephyr.logger.info "[zephyr:#{$$}:#{Time.now.to_f}] \"%s %s\" %s %0.4f" % [
      method.to_s.upcase, response.request.url, response.code, (http_end - http_start)
    ]

    # be consistent with what came before
    response_headers = Headers.new.tap do |h|
      response.headers.split(/\n/).each do |header_line|
        h.parse(header_line)
      end
    end

    if !response.timed_out? && valid_response?(expect, response.code)
      result = { :headers => response_headers.to_hash, :status => response.code }
      if return_body?(method, response.code)
        result[:body] = response.body
      end
      result
    else
      failed_request = FailedRequest.new(:method        => method,
                                         :uri           => response.request.url,
                                         :expected_code => expect,
                                         :timeout       => timeout,
                                         :response      => response)
      Zephyr.logger.error "[zephyr:#{$$}:#{Time.now.to_f}]: #{failed_request}"
      raise failed_request
    end
  end

  def create_request_headers(hash)
    h = Headers.new
    hash.each {|k,v| h.add_field(k,v) }
    [].tap do |arr|
      h.each_capitalized do |k,v|
        arr << "#{k}: #{v}"
      end
    end
  end

  def create_json_response(response, yajl_opts = {})
    return response if response.nil? || !response.key?(:headers) || !response[:headers].key?('content-type')
    content_type = response[:headers]['content-type']
    content_type = content_type.first if content_type.respond_to?(:first)

    if response[:body] && content_type.to_s.strip.match(/^application\/json/)
      response[:json] = Yajl::Parser.parse(response[:body], yajl_opts)
    end
    response
  end

end

# Represents headers from an HTTP request or response.
# Used internally by HTTP backends for processing headers.
class Headers
  include Net::HTTPHeader

  def initialize
    initialize_http_header({})
  end

  # Parse a single header line into its key and value
  # @param [String] chunk a single header line
  def self.parse(chunk)
    line = chunk.strip
    # thanks Net::HTTPResponse
    return [nil,nil] if chunk =~ /\AHTTP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/in
    m = /\A([^:]+):\s*/.match(line)
    [m[1], m.post_match] rescue [nil, nil]
  end

  # Parses a header line and adds it to the header collection
  # @param [String] chunk a single header line
  def parse(chunk)
    key, value = self.class.parse(chunk)
    add_field(key, value) if key && value
  end
end
