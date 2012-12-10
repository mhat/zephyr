module Typhoeus
  module Utils
    def escape(s)
      Zephyr.percent_encode(s)
    end
    module_function :escape
  end
end
