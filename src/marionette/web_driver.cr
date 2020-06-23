module Marionette
  class WebDriver
    include Logger

    getter browser : Browser

    getter! url : URI?

    getter client : HTTP::Client

    getter? w3c : Bool

    getter? keep_alive : Bool

    property capabilities : JSON::Any?

    def initialize(@browser : Browser,
                   @url : URI,
                   @client : HTTP::Client,
                   @keep_alive = false,
                   @w3c = false,
                   @capabilities = nil)
    end

    def self.create_session(browser : Browser,
                            exe_path = nil,
                            port = nil,
                            env = ENV.to_h,
                            args = [] of String,
                            browser_options = {} of String => String)
      service = Service.new(browser, exe_path, port, "127.0.0.1", args, env)
      service.start
      driver = browser.new_remote_web_driver(service.url, keep_alive: true)
      result = driver.get_session(browser_options)
      result.service = service
      result
    end

    def get_session(opts = {} of String => String)
      capabilities = browser.desired_capabilities
      capabilities = capabilities.merge(opts)

      params = {
        "capabilities" => Utils.to_w3c_caps(capabilities),
        "desired_capabilities" => capabilities
      }

      response = execute("NewSession", params)
      if !response["sessionId"]?
        response = response["value"]
      end

      session_id = response["sessionId"].as_s
      @capabilities = response["value"]?

      if !@capabilities
        @capabilities = response["capabilities"]?
      end

      @w3c = !response["status"]?

      Session.new(self, id: session_id, type: :local)
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
      response
    end
  end
end
