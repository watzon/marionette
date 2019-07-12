require "./logger"

class Marionette
  abstract class ConnectionTransport
    include Logger

    @on_message : Proc(String, Void) = ->(message : String) { }

    @on_close : Proc(Void) = ->() { }

    abstract def send(message : String)

    abstract def close

    def on_message(&block : String ->)
      @on_message = block
    end

    def on_close(&block)
      @on_close = block
    end

  end
end

require "./connection_transport/*"
