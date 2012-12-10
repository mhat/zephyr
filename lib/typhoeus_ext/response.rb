module Typhoeus
  class Response
    def retryable_request?
      timed_out? || (500..599).include?(code)
    end
  end
end
