require "uri"
require "http/client"
require "http/server"

module Marionette
  class Proxy
    include Logger

    getter browser : Browser

    property port    : Int32?

    property request  : HTTP::Request
    property response : HTTP::Client::Response?

    property callback : (HTTP::Server::Context ->)?

    def initialize(@browser)
      @request = HTTP::Request.new("GET", "about:config")
      @port = 6969
      @first = true

      launch
    end

    {% for method in [:get, :post, :patch, :head, :delete] %}
      def {{ method.id }}(url, headers = nil, body = nil)
        exec({{ method.id.stringify.upcase }}, url, headers, body)
      end
    {% end %}

    def exec(request : ::HTTP::Request) : HTTP::Client::Response
      exec(request.method, request.resource, request.headers, request.body.to_s)
    end

    def exec(method : String, url : String, headers : ::HTTP::Headers? = nil, body : String? = nil) : ::HTTP::Client::Response
      @first = true
      @request = HTTP::Request.new(method, url, headers, body)
      @browser.navigate "http://127.0.0.1:#{@port}"
      30.times do
        if (response = @response.dup)
          @response = nil
          return response
        end
        sleep 1
      end
      raise "Timeout when trying to get response"
    end

    def launch
      server = HTTP::Server.new do |ctx|
        begin
          uri = URI.parse(@request.resource)

          debug("Marionette called Proxy-Server with: #{ctx.request.inspect}")

          server_headers = ctx.request.headers
          server_headers.delete("Content-Length")
          server_headers["Accept-Encoding"] = "identity"
          if (cookie = ctx.request.headers["Cookie"]?)
            server_headers["Cookie"] = cookie
          end

          @callback.try &.call(ctx)

          if @first # Change!
            response = HTTP::Client.exec(@request.method, @request.resource, ctx.request.headers, @request.body)
            body = rewrite(response, uri)
            @response = response
            debug("Proxy Sent: #{@request.resource}")
            @first = false
          else # Proxy!
            debug("Proxy Sent Followup: #{ctx.request.resource} and body: #{ctx.request.body.to_s}")
            # Fix rewrite
            tmp_uri = URI.parse(ctx.request.resource)
            tmp_uri.host = uri.host
            tmp_uri.scheme = uri.scheme
            tmp_uri.port = uri.port
            tmp_headers = server_headers
            tmp_headers["Host"] = uri.host.to_s
            response = HTTP::Client.exec(ctx.request.method, tmp_uri.to_s, tmp_headers, ctx.request.body.to_s)
            body = rewrite(response, uri)
          end
        rescue ex : Exception
          error("Error executing request: #{ex.inspect_with_backtrace}")
          error("URI tried was: #{@request.resource}")
          ctx.response.status_code = 500
          ctx.response.print("")
          next
        end

        ctx.response.headers.merge!(response.headers)
        ctx.response.status_code = response.status_code
        ctx.response.print(body.to_s)
      end

      begin
        @port = server.bind_unused_port("0.0.0.0").port
        debug("Proxy-Server attached at: 127.0.0.1:#{@port}. Waiting for Marionette.")
      rescue ex : Exception
        raise "Error binding the proxy-loop for 127.0.0.1:#{@port} in Webdriver.exec: #{ex.inspect_with_backtrace}"
      end

      spawn do
        server.listen
      end

      at_exit do
        server.close unless server.closed?
      end

      server
    end

    private def rewrite(response : HTTP::Client::Response, uri : URI) : String
      original_body = response.body
      return original_body if original_body.empty?
      return original_body unless response.headers["Content-Type"]?.to_s.includes?("text")

      original_body
        .gsub(
          /(src|href|rel)=(["'])((?:http|https):\/\/#{uri.to_s})?([.]*\/.*)(["'])/,
          "\\1=\\2http://127.0.0.1:#{@port}/\\3\\4\\5"
        )
    end

  end
end

