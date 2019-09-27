require "socket"
require "json"

module Marionette
  class Transport
    include Logger

    property max_packet_length : Int32
    property min_protocol_level : Int32

    getter timeout : Int32
    getter last_id : Int32

    @socket : TCPSocket

    # Creates a new Transport instance with the
    # provided `timeout`.
    def initialize(addr : String, port : Int32, @timeout : Int32 | Time::Span = 60.seconds)
      @socket = TCPSocket.new(addr, port, dns_timeout: @timeout, connect_timeout: @timeout)
      @socket.read_timeout = @timeout
      @socket.write_timeout = @timeout
      @last_id = 0
      @max_packet_length = 2048
      @min_protocol_level = 3
    end

    # Initiates a TCP connection to a running Firefox instance
    # using the provided `address` and `port`.
    def connect
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

      len = @socket.gets(':').to_s.chomp(':').to_i

      until data.bytesize == len
        remaining = len - data.bytesize
        num_bytes = [@max_packet_length, remaining].min
        data += @socket.read_string(num_bytes)
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
      @socket.send("#{json.bytesize}:#{json}")
    end

    def finalize
      @socket.close unless @socket.closed?
    end

    # Convenience method to `send` a command with
    # optional `params` and `receive` a `Message`
    # response.
    def request(command, params = nil)
      send(command, params)
      receive
    end
  end

  record Message, type : Int32, id : Int32, command : String?, params : JSON::Any do
    def [](key)
      params[key]
    end

    def []?(key)
      if params?
        params[key]?
      end
    end

    def params?
      begin
        params.as_nil
        return false
      rescue
        return true
      end
    end
  end
end
