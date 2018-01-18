require "uri"
require "json"
require "http/web_socket"

module PuppetMaster
  class Connection

    property :url, :ws, :delay, :last_id, :sessions, :close_callback

    @close_callback : Proc(String?, Nil)? = nil

    def initialize(@url : String, @ws : HTTP::WebSocket, @delay = 0)
      @last_id = 0
      @sessions = {} of String => String
      @message_channel = Channel(JSON::Any).new
      @ws.on_close { |m| on_close m }
      spawn do
        @ws.run
      end
    end

    def self.create(url, delay = 0)
      ws = HTTP::WebSocket.new(URI.parse(url))
      new(url, ws, delay)
    end

    def next_id
      @last_id += 1
    end

    def send(method, params)
      id = next_id
      message = { id: id, method: method, params: params }
      ch = Channel(String).new
      
      @ws.send(message.to_json)
      @ws.on_message { |m| ch.send(m) }

      message = JSON.parse(ch.receive)
      if message["id"]
        return message["result"]
      else
        case message["method"]
        when "Target.receivedMessageFromTarget"

        when "Target.detachedFromTarget"
          
        else
          
        end
      end
    end

    def send(method, params, &block)
      yield send(method, params)
    end

    def dispose
      on_close
      @ws.close
    end

    private def on_close(close : String?)

    end

  end
end
