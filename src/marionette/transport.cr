require "socket"
require "json"

module Marionette
  class Transport
    include Logger

    property max_packet_length : Int32
    property min_protocol_level : Int32
    
    getter timeout : Int32
    getter last_id : Int32

    private getter socket : Socket

    # Creates a new Transport instance with the
    # provided `timeout`.
    def initialize(@timeout = 60000)
      @socket = Socket.tcp(Socket::Family::INET)
      @last_id = 0
      @max_packet_length = 2048
      @min_protocol_level = 3
      
      at_exit do
        socket.close unless socket.closed?
      end
    end

    # Initiates a TCP connection to a running Firefox instance
    # using the provided `address` and `port`.
    def connect(address, port)
      try_connect(address, port, @timeout)

      begin
        # Utils.timeout(@timeout) do
        response = JSON.parse(receive_raw)
        # end
      rescue Error::TimeoutError
        raise Error::TimeoutError.new("Connection attempt failed because no data has been received over the socket")
      end

      application_type = response["applicationType"].as_s
      protocol = response["marionetteProtocol"].as_i

      if application_type != "gecko"
        raise "Application type '#{application_type}' is not supported"
      end

      if protocol < min_protocol_level
        raise "Earliest supported protocol is '#{min_protocol_level}', but got '#{protocol}'"
      end

      {protocol: protocol, application_type: application_type}
    end

    # Receives a message from the browser following
    # a command and parses it into a `Message` instance.
    def receive
      raw = receive_raw
      type, id, command, params = JSON.parse(raw).as_a
      Message.new(type.as_i, id.as_i, command.as_s?, params)
    end

    # Receives a message from the browser following
    # a command and returns the raw string.
    # TODO: Add timeout
    def receive_raw
      now = Time.now
      data = ""

      len = socket.gets(':').to_s.chomp(':').to_i

      until data.bytesize == len
        remaining = len - data.bytesize
        num_bytes = [@max_packet_length, remaining].min        
        data += socket.read_string(num_bytes)
      end

      data
    end

    # Sends a `command` to the browser with optional
    # `params` supplied as any object that can be
    # converted to json via `#to_json`.
    def send(command, params = nil)
      msg_id = @last_id += 1
      params ||= {} of String => String
      data = params.to_json
      payload = [0, msg_id, command, params]
      json = payload.to_json
      socket.send("#{json.size}:#{json}")
    end

    # Convenience method to `send` a command with
    # optional `params` and `receive` a `Message`
    # response.
    def request(command, params = nil)
      send(command, params)
      receive
    end

    private def try_connect(address, port, timeout)
      now = Time.now
      connected = false
      
      until connected || Time.now >= (now + timeout.milliseconds)
        begin
          @socket.connect(address, port)
          connected = true
          debug("connected to firefox at #{address}:#{port}")
          return
        rescue ex
        end
      end

      raise "Timed out while attemting to connect to firefox"
    end
  end

  record Message, type : Int32, id : Int32, command : String?, params : JSON::Any do
    delegate :[], :[]?, to: params
  end
end

# require "base64"

# transport = Marionette::Transport.new
# transport.connect("127.0.0.1", 2828)
# pp transport.request("WebDriver:NewSession", {acceptInsecureCerts: true, browserName: "firefox", timeouts: { implicit: 30000, pageLoad: 30000,  script: 30000}})
# pp transport.request("WebDriver:Navigate", {url: "https://neuralegion.com"})
# source = transport.request("WebDriver:TakeScreenshot", {full: true, hash: false})
# b64 = source["value"].as_s
# File.write("screenshot.jpg", Base64.decode_string(b64))
