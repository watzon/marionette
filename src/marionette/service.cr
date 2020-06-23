require "socket"

module Marionette
  class Service
    SERVICE_CHECK_INTERVAL = 100.milliseconds
    SERVICE_RETRY_LIMIT = 10

    getter browser : Browser

    getter path : String
    getter port : Int32
    getter env  : Hash(String, String)

    getter process : Process?
    getter stdout  : IO::Memory
    getter stderr  : IO::Memory

    def initialize(@browser : Browser,
                   path = nil,
                   port = nil,
                   @host = "127.0.0.1",
                   @args = [] of String,
                   @env = ENV.to_h)
      @path = path ? path : browser.default_exe
      @port = port ? port : Utils.random_open_port(@host)

      @stdout = IO::Memory.new
      @stderr = IO::Memory.new
    end

    def url
      @browser.url(@host, @port)
    end

    def command_line_args
      result = [] of String
      case @browser
      when Browser::Firefox
        result.concat ["--port", @port.to_s]
        unless @host.empty?
          result.concat ["--host", @host]
        end
      when Browser::Chrome, Browser::Chromium
        result.concat ["--port=#{@port}"]
      when Browser::InternetExplorer
        result.concat ["--port=#{@port}"]
        unless @host.empty?
          result.concat ["--host", @host]
        end
      when Browser::Safari
        result.concat ["--port", @port.to_s]
      when Browser::PhantomJS
        result.concat ["--webdriver", @port.to_s]
      when Browser::WebkitGTK, Browser::WPEWebkit
        result.concat ["-p", @port.to_s]
      end
      result.concat @args
    end

    def send_remote_shutdown
      if open?
        HTTP::Client.get(File.join(url.to_s, "shutdown"))
        0.upto(30).each do
          if open?
            sleep 1000
          else
            break
          end
        end
      end
    end

    def open?
      sock = TCPSocket.new(@host.empty? ? "127.0.0.1" : @host, @port)
      sock.close
      true
    rescue Socket::ConnectError
      false
    end

    def closed?
      !open?
    end

    def stop
      if process = @process
        send_remote_shutdown

        begin
          process.signal(Signal::INT)
          process.signal(Signal::KILL)
          @process = nil
        rescue ex
        end
      end
    end

    def start
      begin
        @process = Process.new(
          command: @path,
          args: command_line_args,
          env: @env,
          shell: true,
          output: @stdout,
          error: @stderr
        )

        count = 0
        loop do
          assert_process_still_running

          if open?
            break
          else
            count += 1
            sleep(SERVICE_CHECK_INTERVAL)
            if count >= SERVICE_RETRY_LIMIT
              raise "Cannot connect to service #{@path}."
            end
          end
        end
      rescue ex : File::NotFoundError
        raise "'#{@path}' could not be found in your PATH environment variable. #{@browser.startup_message}"
      rescue ex : File::AccessDeniedError
        raise "'#{@path}' may have the wrong permissions. Please set binary as executable and readable by the current user."
      end
    end

    private def assert_process_still_running
      if !@process || ((process = @process) && process.terminated?)
        raise "Service #{@path} unexpectedly exited."
      end
    end
  end
end
