require "http_proxy"

module Marionette
  class Proxy
    include Logger
    
    getter server : HTTP::Proxy::Server
    getter address : String
    getter port : Int32

    def initialize(address, port)
      @address = address
      @port = port

      @server = HTTP::Proxy::Server.new(address, port, handlers: [
        HTTP::ErrorHandler.new,
        HTTP::LogHandler.new,
        TrafficHandler.new
      ])

      at_exit do
        @server.close unless server.closed?
      end
    end

    def start
      @server.bind_tcp @port
      debug("Proxy server listening at #{@address}:#{@port}")
      spawn server.listen
    end

    class TrafficHandler
      include Logger
      include HTTP::Handler

      def call(context)
        debug(context.inspect)
        call_next(context)
      end
    end
  end
end