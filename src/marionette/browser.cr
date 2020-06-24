module Marionette
  enum Browser
    Chrome
    Chromium
    Firefox
    Safari
    Edge
    InternetExplorer
    Opera
    PhantomJS
    WebkitGTK
    WPEWebkit
    Android

    def new_remote_web_driver(url, keep_alive = true)
      WebDriver.new(browser: self, url: url(url.host, url.port), client: HTTP::Client.new(url), keep_alive: keep_alive)
    end

    def url(host, port)
      case self
      when Browser::PhantomJS, Browser::Android
        URI.parse("http://#{host}:#{port}/wd/hub")
      else
        URI.parse("http://#{host}:#{port}")
      end
    end

    def startup_message
      case self
      when Chrome, Chromium
        "Please see https://chromedriver.chromium.org/home"
      when InternetExplorer
        "Please download from http://selenium-release.storage.googleapis.com/index.html"
      else
        ""
      end
    end

    def desired_capabilities
      caps = case self
      in Firefox
        {
          "browserName" => "firefox",
          "acceptInsecureCerts" => true
        }
      in Chrome, Chromium
        {
          "browserName" => "chrome",
          "version" => "",
          "platform" => "ANY"
        }
      in Edge
        {
          "browserName" => "MicrosoftEdge",
          "version" => "",
          "platform" => "ANY"
        }
      in InternetExplorer
        {
          "browserName" => "internet explorer",
          "version" => "",
          "platform" => "WINDOWS"
        }
      in Opera
        {
          "browserName" => "opera",
          "version" => "",
          "platform" => "ANY"
        }
      in Safari
        {
          "browserName" => "safari",
          "version" => "",
          "platform" => "MAC"
        }
      in PhantomJS
        {
          "browserName" => "phantomjs",
          "version" => "",
          "platform" => "ANY",
          "javascriptEnabled" => true
        }
      in Android
        {
          "browserName" => "android",
          "version" => "",
          "platform" => "ANDROID"
        }
      in WebkitGTK
        {
          "browserName" => "MiniBrowser",
          "version" => "",
          "platform" => "ANY"
        }
      in WPEWebkit
        {
          "browserName" => "MiniBrowser",
          "version" => "",
          "platform" => "ANY"
        }
      end

      caps.transform_values { |v| JSON::Any.new(v) }
    end

    def default_exe
      case self
      in Firefox
        "geckodriver"
      in Chrome, Chromium
        "chromedriver"
      in Edge
        "MicrosoftWebDriver.exe"
      in InternetExplorer
        "IEDriverServer.exe"
      in Opera
        "operadriver"
      in Safari
        "/usr/bin/safaridriver"
      in PhantomJS
        "phantomjs"
      in WebkitGTK
        "WebKitWebDriver"
      in WPEWebkit
        "WPEWebDriver"
      in Android
        raise "There is no service executable for Android. Please use a remote webdriver instead."
      end
    end

    def command_tuple(command)
      case self
      when Firefox
        FirefoxCommands[command]
      when Chrome, Chromium
        ChromiumCommands[command]
      when Safari
        SafariCommands[command]
      else
        BasicCommands[command]
      end
    end
  end
end
