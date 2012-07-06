module Typhoeus
  module Utils
    def escape(s)
      Zephyr.percent_encode(s, s.bytesize)
    end
    module_function :escape
  end
end

module Typhoeus
  class Request
    def params_string
      Zephyr.build_query_string(params)
    end
  end
end