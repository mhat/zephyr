class Zephyr
  # Raised when a request fails due to either a timeout or when the expected
  # response code does not match the actual response code.
  class FailedRequest < StandardError
    attr_reader :method, :uri, :expected_code, :timeout, :response

    # The following options are required:
    #
    # method        - The HTTP method used for the request.
    # uri           - The uri of the request.
    # expected_code - The expected response code for the request.
    # timeout       - The timeout (in milliseconds) for the request.
    # response      - The response.
    def initialize(options)
      @method        = options[:method].to_s.upcase
      @uri           = options[:uri]
      @expected_code = options[:expected_code]
      @timeout       = options[:timeout]
      @response      = options[:response]

      super "#{@method} #{@uri} - #{error_message}"
    end

    # Returns whether the request timed out.
    def timed_out?
      @response.timed_out? || @response.code == 0
    end

    private
      def error_message
        if timed_out?
          "Response exceeded #{@timeout}ms."
        else
          "Expected #{@expected_code} from the server but received #{@response.code}."
        end
      end
  end
end
