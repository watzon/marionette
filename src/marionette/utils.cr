module Marionette
  module Utils
    extend self

    W3CCapabilityNames = [
      "acceptInsecureCerts",
      "browserName",
      "browserVersion",
      "platformName",
      "pageLoadStrategy",
      "proxy",
      "setWindowRect",
      "timeouts",
      "unhandledPromptBehavior",
      "strictFileInteractability"
    ]

    OssW3CConversion = {
      "acceptSslCerts" => "acceptInsecureCerts",
      "version" => "browserVersion",
      "platform" => "platformName"
    }

    def random_open_port(host)
      server = TCPServer.new(host, 0)
      port = server.local_address.port
      server.close
      port
    end

    def to_w3c_caps(caps)
      caps = JSON.parse(caps.to_json)
      always_match = {} of String => JSON::Any

      caps.as_h.each do |k, v|
        if v.is_a?(String) && v.size > 0 && OssW3CConversion.has_key?(k)
          always_match[OssW3CConversion[k]] = JSON::Any.new(k == "platform" ? v.downcase : v)
        end

        if k.includes?(':') || W3CCapabilityNames.includes?(k)
          always_match[k] = v
        end
      end

      {firstMatch: [{} of String => String], alwaysMatch: always_match}
    end

    def which(cmd)
      exts = ENV["PATHEXT"]? ? ENV["PATHEXT"].split(";") : [""]
      ENV["PATH"].split(':').each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe)
        }
      end
      nil
    end

    def timeout(time, &block)
      start = Time.monotonic
      channel = Channel(Bool).new
      spawn do
        until Time.monotonic > (start + time.milliseconds)
        end
        channel.send(false)
      end

      spawn do
        block.call
        channel.send(true)
      end

      unless channel.receive
        raise Error::TimeoutError.new
      end
    end

    def selector_params(selector : String, strategy : LocationStrategy, w3c = false)
      modified_selector = selector
      modified_strategy = strategy

      if w3c
        case strategy
        when LocationStrategy::ID
          modified_selector = "[id=\"{selector}\"]"
          modified_strategy = LocationStrategy::Css
        when LocationStrategy::TagName
          modified_strategy = LocationStrategy::Css
        when LocationStrategy::ClassName
          modified_strategy = LocationStrategy::Css
          modified_selector = ".{selector}"
        when LocationStrategy::Name
          modified_strategy = LocationStrategy::Css
          modified_selector = "[name=\"{selector}\"]"
        end
      end

      {
        "using" => modified_strategy.to_s,
        "value" => modified_selector
      }
    end
  end
end
