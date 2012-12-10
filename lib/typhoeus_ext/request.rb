module Typhoeus
  class Request
    def params_string
      Zephyr.build_query_string(params)
    end
  end
end
