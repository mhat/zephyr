module Typhoeus
  class Request
    def params_string
      return nil unless params
      Zephyr.build_query_string(params)
    end
  end
end
