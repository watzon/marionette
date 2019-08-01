require "http/server"

module Marionette
  class Proxy
    include Logger

    getter server : HTTP::Server
    getter address : String
    getter port : Int32
    getter last_request : HTTP::Request?
    getter last_response : HTTP::Server::Response?

    def initialize(@address, @port)
      @server = HTTP::Server.new([
        HTTP::LogHandler.new,
        TransparentHandler.new
      ])

      at_exit do
        @server.close unless server.closed?
      end
    end

    def self.launch(address, port)
      proxy = new(address, port)
      proxy.start
      proxy
    end

    def start
      @server.bind_tcp @address, @port
      debug("Proxy server listening at #{@address}:#{@port}")
      spawn do
        server.listen
      end
      while server.closed?
      end
    end

    class TransparentHandler
      include HTTP::Handler

      def call(context)

      end
    end
  end
end
