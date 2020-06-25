module Marionette
  class WebDriver
    include Logger

    getter browser : Browser

    getter! url : URI?

    getter client : HTTP::Client

    getter? keep_alive : Bool

    def initialize(@browser : Browser,
                   @url : URI,
                   @client : HTTP::Client,
                   @keep_alive = false)
    end

    # Create a new `Session` instance using the given `browser`. If the driver is
    # not on your PATH or is under a different name, you may want to
    # provide its path explicitly using `exe_path`.
    #
    # When the driver is started it will be automatically assigned a random
    # open port. If you want to assign a port explicitly you can do so
    # using the `port` parameter.
    #
    # The environment variables the driver is exposed to can be set using `env`.
    #
    # All other keyword arguments are passed directly into the `get_session` call,
    # which are then passed into `Session.start`.
    def self.create_session(browser : Browser,
                            exe_path = nil,
                            port = nil,
                            env = ENV.to_h,
                            args = [] of String,
                            **options)
      service = Service.new(browser, exe_path, port, "127.0.0.1", args, env)
      service.start
      driver = browser.new_remote_web_driver(service.url, keep_alive: true)
      result = driver.get_session(**options)
      result.service = service
      result
    end

    def get_session(type : Session::Type = :local, **options)
      Session.start(self, type, **options)
    end

    def connection_headers(url : String | URI, keep_alive : Bool = false)
      uri = url.is_a?(URI) ? url : URI.parse(url)

      headers = HTTP::Headers{
        "Accept" => "application/json",
        "Content-Type" => "application/json;charset=UTF-8",
        "User-Agent" => "Marionette #{Marionette::VERSION} (Crystal #{Crystal::VERSION})"
      }

      if uri.user
        encoded_creds = Base64.encode("#{uri.user}:#{uri.password}")
        headers["Authorization"] = "Basic #{encoded_creds}"
      end

      if keep_alive
        headers["Connection"] = "keep-alive"
      end

      headers
    end

    def request(method, url, body = {} of String => String, headers = nil)
      req_headers = connection_headers(url, @keep_alive)
      req_headers.merge!(headers) if headers

      body = body.to_json
      response = @client.exec(method.to_s.upcase, url, req_headers, body)

      JSON.parse(response.body)
    end

    def execute(command : String, params = {} of String => String)
      begin
        method, path = browser.command_tuple(command)
      rescue ex : KeyError
        raise "Command #{command} not valid for browser #{self.class}"
      end

      params.map do |k, v|
        if k.starts_with?('$')
          path = path.gsub(k, v)
        end
      end

      data = params.to_a.reject { |k, _| k.starts_with?('$') }.to_h
      response = request(method, path, data)

      if response["value"].as_h? && (error = response.dig?("value", "error"))
        error = response.dig?("value", "message") || error
        raise Error.from_json(error)
      end

      response
    end
  end
end
