require "event_emitter"
require "uri"
require "json"
require "http/web_socket"
require "./logger"
require "./cdp_session"

class Marionette
  class Connection < EventEmitter::Base
    include Logger

    getter url : String
    getter transport : ConnectionTransport
    getter message_delay : Int32
    getter last_id : Int32
    getter sessions : Hash(String, CDPSession)

    @closed : Bool

    # Creates a new instance of `Connection` with the specified
    # `url`, `transport`, and `message_delay`.
    def initialize(@url : String, @transport : ConnectionTransport, @message_delay = 0)
      @last_id = 0
      @sessions = {} of String => CDPSession
      @closed = false
      @transport.on_message do |message|
        puts message
        on_message(message)
      end

      all do |e, _|
        puts e
      end
    end

    # Send a message to the chrome instance. Objects will
    # be converted to JSON before sending.
    def send(method, params = {} of String => String)
      id = @last_id += 1
      message = { method: method, params: params }.to_json
      debug("SEND ► #{message}")
      transport.send(message)
      id
    end

    def on_message(message : String)
      if ms = @message_delay
        sleep(ms)
      end

      debug("◀ RECV #{message}")

      object = JSON.parse(message)

      if object["method"] == "Target.attachedToTarget"
        session_id = object["params"]["sessionId"].as_s
        session = CDPSession.new(self, object["params"]["targetInfo"]["type"].as_s, session_id)
        sessions[session_id] = session
      elsif object["method"] == "Target.detachedFromTarget"
        session = sessions[object["params"]["sessionId"].as_s]?
        if sess = session
          sess.on_closed
          sessions.delete(object["params"]["sessionId"].as_s)
        end
      end

      if session_id = object["session_id"]?
        session = sessions[session_id]?
        session.try &.on_message(object)
      else
        emit(object["method"].as_s, object["params"].as_h)
      end
    end

    def on_close(&block : Void ->)
      return if closed?
      @closed = true
      @sessions.each |session|
        session.on_closed
      @sessions.clear
      yield
    end

    def closed?
      @closed
    end

    def dispose
      on_close
      transport.close
      debug("connection to browser closed")
    end

    struct BrowserMessage
      include JSON::Serializable

      getter id : Int32?

      @[JSON::Field(key: "sessionId")]
      getter session_id : Int32?

      getter method : String

      getter params : Hash(String, JSON::Any)

      getter result

      def initialize(@id, @session_id, @method, @params)
      end

    end
  end
end
