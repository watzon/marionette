module Marionette
  class Error < Exception
    class ExecutableNotFound < Error; end

    class MaxPayloadSizeExceeded < Error; end

    class TimeoutError < Error; end
  end
end
