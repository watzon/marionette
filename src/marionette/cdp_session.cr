class Marionette
  class CDPSession

    getter connection : Connection?

    getter target_type : String

    getter session_id : String

    getter callbacks : Hash(Int32, Proc(JSON::Any, Void))

    def initialize(@connection : Connection, @target_type : String, @session_id : String)
      @callbacks = {} of Int32 => Proc(JSON::Any, Void)
    end

    def send(method, params, &block)
      raise Error::ProtocolError.new("ession closed. Most likely the #{target_type} has been closed.") unless @connection
      id = @connection.send({ "sessionId" => session_id, "method" => method, "params" => params })
      callbacks[id] = block
    end

    def on_message(object)
      if object["id"]? && callbacks.has_key?(object["id"].as_s)
        callback = callbacks.delete(object["id"].as_s)
        callback.call(object["result"])
      else
        raise "Object has no id" unless object["id"]?
      end
    end

    def detach
      if conn = @connection
        conn.send("Target.detachFromTarget", { "sessionId" => @session_id })
      else
        raise "Session already detached. Most likely the #{target_type} has been closed."
      end
    end

    def on_closed(&block)
      @callbacks.clear
      @connection = nil
    end
  end
end
