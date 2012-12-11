module Typhoeus
  class Response
    def retryable_request?
      timed_out? || connection_failed? || server_error?
    end

    def connection_failed?
      curl_return_code == 7
    end

    def server_error?
      (500..599).include?(code)
    end
  end
end
