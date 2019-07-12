class Marionette
  class Error < Exception

    class ExecutableNotFound < Error; end

    class MaxPayloadSizeExceeded < Error; end

  end
end
