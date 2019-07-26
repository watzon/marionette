require "uri"
require "http/web_socket"

class Marionette
  class WebsocketTransport < ConnectionTransport

    getter ws : HTTP::WebSocket

    def self.create(url, headers = nil)
      url = URI.parse(url) unless url.is_a?(URI)
      ws = HTTP::WebSocket.new(url, headers || HTTP::Headers.new)
      new(ws)
    end

    def initialize(@ws : HTTP::WebSocket)
      @ws.on_message { |message| @on_message.call(message) }
      @ws.on_close   { @on_close.call }
    end

    def send(message : String)
      raise Error::MaxPayloadSizeExceeded.new if message.bytesize > (256 * 1024 * 1024) # 256MB
      @ws.send(message)
    end

    def close
      @ws.close
    end
  end
end
