require "base64"
require "json"

module Marionette
  class Browser
    CHROME_ELEMENT_KEY = "chromeelement-9fc5-4b51-a3c8-01716eedeb04"
    FRAME_KEY          = "frame-075b-4da1-b6ba-e579c2d3230a"
    WEB_ELEMENT_KEY    = "element-6066-11e4-a52e-4f735466cecf"
    WINDOW_KEY         = "window-fcc6-11e5-b4f8-330a88ab9d7f"

    KEYS = {
      null:         '\ue000',
      cancel:       '\ue001', # ^break
      help:         '\ue002',
      back_space:   '\ue003',
      tab:          '\ue004',
      clear:        '\ue005',
      return:       '\ue006',
      enter:        '\ue007',
      shift:        '\ue008',
      left_shift:   '\ue008', # alias
      control:      '\ue009',
      left_control: '\ue009', # alias
      alt:          '\ue00a',
      left_alt:     '\ue00a', # alias
      pause:        '\ue00b',
      escape:       '\ue00c',
      space:        '\ue00d',
      page_up:      '\ue00e',
      page_down:    '\ue00f',
      end:          '\ue010',
      home:         '\ue011',
      left:         '\ue012',
      arrow_left:   '\ue012', # alias
      up:           '\ue013',
      arrow_up:     '\ue013', # alias
      right:        '\ue014',
      arrow_right:  '\ue014', # alias
      down:         '\ue015',
      arrow_down:   '\ue015', # alias
      insert:       '\ue016',
      delete:       '\ue017',
      semicolon:    '\ue018',
      equals:       '\ue019',

      numpad0:   '\ue01a', # number pad  keys
      numpad1:   '\ue01b',
      numpad2:   '\ue01c',
      numpad3:   '\ue01d',
      numpad4:   '\ue01e',
      numpad5:   '\ue01f',
      numpad6:   '\ue020',
      numpad7:   '\ue021',
      numpad8:   '\ue022',
      numpad9:   '\ue023',
      multiply:  '\ue024',
      add:       '\ue025',
      separator: '\ue026',
      subtract:  '\ue027',
      decimal:   '\ue028',
      divide:    '\ue029',

      f1:  '\ue031', # function  keys
      f2:  '\ue032',
      f3:  '\ue033',
      f4:  '\ue034',
      f5:  '\ue035',
      f6:  '\ue036',
      f7:  '\ue037',
      f8:  '\ue038',
      f9:  '\ue039',
      f10: '\ue03a',
      f11: '\ue03b',
      f12: '\ue03c',

      meta:    '\ue03d',
      command: '\ue03d',
    }

    enum BrowserContext
      Chrome
      Content
    end

    enum ScreenshotFormat
      Base64
      Hash
      Binary
    end

    # Strategy for finding elements
    enum LocatorStrategy
      ID
      Name
      ClassName
      TagName
      LinkText
      PartialLinkText
      XPATH

      def to_s
        super.underscore.downcase.gsub('_', " ")
      end
    end

    getter transport : Synchronized(Transport)

    getter proxy : Proxy?

    getter timeout : Time::Span

    getter? session_id : String?

    getter? extended : Bool

    # id of the marionette browser , used for logging.
    getter id : String?

    def initialize(@address : String, @port : Int32, @extended = false, @timeout : Time::Span = 60.seconds, warmup_timeout = 3.seconds)
      @transport = warmup_transport(Time.utc + warmup_timeout) || init_transport
      @transport.connect
      launch_proxy if extended

      @session_id = nil
      @id = UUID.random.hexstring[..8]
      Log.debug { "(#{@id}) Initialized a new browser instance" }
    end

    def init_transport
      Synchronized(Transport).new(Transport.new(@address, @port, @timeout))
    end

    # wait for browser to start
    def warmup_transport(give_up_time)
      begin
        return init_transport
      rescue exception : Socket::ConnectError
        sleep 0.1
        return nil if give_up_time < Time.utc
        warmup_transport(give_up_time)
      end
    end

    # Starts the proxy server
    def launch_proxy
      @proxy = Proxy.new(self)
    end

    # Create a new browser session
    def new_session(capabilities)
      Log.debug { "(#{@id}) Creating new session with capabilities: #{capabilities}" }
      response = @transport.request("WebDriver:NewSession", capabilities)
      @session_id = response["sessionId"].as_s
    end

    # Closes the current session without shutting down the browser
    def close_session
      @transport.request("WebDriver:DeleteSession")
    end

    # Disable's Firefox's inbuilt caching mechanism
    def disable_cache
      set_pref("browser.cache.disk.enable", false)
      set_pref("browser.cache.memory.enable", false)
      set_pref("browser.cache.offline.enable", false)
      set_pref("network.http.use-cache", false)
    end

    # Enable's Firefox's inbuilt caching mechanism
    def enable_cache
      set_pref("browser.cache.disk.enable", true)
      set_pref("browser.cache.memory.enable", true)
      set_pref("browser.cache.offline.enable", true)
      set_pref("network.http.use-cache", true)
    end

    # Passes the full server context for each request to
    # the given block. Only works if the `extended`
    # is true option.
    def on_request(&block : HTTP::Server::Context ->)
      if proxy = @proxy
        proxy.on_request(&block)
      end
    end

    # Passes each rrsponse header to the provided block.
    # Only works if the `extended` option is true.
    def on_headers(&block : HTTP::Headers ->)
      if proxy = @proxy
        proxy.on_request do |ctx|
          block.call(ctx.response.headers)
        end
      end
    end

    # Passes each captured `HAR::Entry` object to the
    # provided block. Only works if the `extended` option is true.
    def on_har_capture(&block : HAR::Entry ->)
      if proxy = @proxy
        proxy.on_har_capture(&block)
      end
    end

    # Returns all captured `HAR::Entry` objects so far.
    # Only works if the `extended` option is true.
    def har_entries
      if proxy = @proxy
        return proxy.har_entries
      end
      return [] of HAR::Entry
    end

    # Generates and returns a `HAR::Data` object.
    # Only works if the `extended` option is true.
    def generate_har
      if proxy = @proxy
        log = HAR::Log.new
        log.entries = har_entries
        HAR::Data.new(log)
      end
    end

    # Generates and saves a har file to the provided path.
    # You can optionally provide it a har file to save.
    # Only works if the `extended` option is true.
    def export_har(file, har = nil)
      if proxy = @proxy
        har = generate_har unless har
        File.write(file, har.to_json)
      end
    end

    # Navigate to the specified `url`
    def goto(url)
      if proxy = @proxy
        proxy.reset
        response = proxy.get(url, body: {url: url}.to_json)
        # Log.debug { "Marionette got #{response.body.to_s}" }
        nil
      else
        navigate(url)
      end
    rescue e : Socket::Error | IO::Error
      Log.error(exception: e) { "(#{id}) Broken pipe Browser request failed on #{url}: #{e.inspect_with_backtrace}" }
      raise e
    rescue e : Exception
      Log.error(exception: e) { "(#{id}) Browser request failed on #{url}: #{e.inspect_with_backtrace}" }
      raise "Browser request error"
    end

    # :nodoc:
    def navigate(url)
      Log.debug { "(#{@id}) Navigating to #{url}" }
      @transport.request("WebDriver:Navigate", {url: url})
      nil
    end

    # Get the title of the current page
    def title : String?
      response = @transport.request("WebDriver:GetTitle")
      if response
        response["value"]?.try &.as_s?
      end
    end

    # Get the current url
    def url : String?
      response = @transport.request("WebDriver:GetCurrentURL")
      if response
        response["value"]?.try &.as_s?
      end
    end

    # Refresh the page
    def refresh
      Log.debug { "(#{@id}) Refreshing page" }
      @transport.request("WebDriver:Refresh")
      nil
    end

    # Go back
    def back
      Log.debug { "(#{@id}) Going back" }
      @transport.request("WebDriver:Back")
      nil
    end

    # Go forward
    def forward
      Log.debug { "(#{@id}) Going forward" }
      @transport.request("WebDriver:Forward")
      nil
    end

    # Sets the context of subsequent commands to be either
    # chrome or content.
    def set_context(context : BrowserContext)
      Log.debug { "(#{@id}) Setting browser context to #{context.to_s}" }
      @transport.request("Marionette:SetContext", {value: context.to_s.downcase})
    end

    # Gets the current browser context
    def context
      response = @transport.request("Marionette:GetContext")
      case response["value"].as_s
      when "chrome"
        BrowserContext::Chrome
      else
        BrowserContext::Content
      end
    end

    # Sets the context for the block, then returns it to
    # its previous state.
    def using_context(context : BrowserContext, &block)
      scope = self.context
      set_context(context)
      output = with self yield self
      set_context(scope)
      output
    end

    # Returns the current window's handle.
    #
    # Returns an opaque server-assigned identifier to this window
    # that uniquely identifies it within this Marionette instance.
    # This can be used to switch to this window at a later point.
    def current_window_handle
      response = @transport.request("WebDriver:GetWindowHandle")
      response["value"].as_s
    end

    # Get the current chrome window's handle. Corresponds to
    # a chrome window that may itself contain tabs identified by
    # window_handles.
    #
    # Returns an opaque server-assigned identifier to this window
    # that uniquely identifies it within this Marionette instance.
    # This can be used to switch to this window at a later point.
    def current_chrome_window_handle
      @transport.request("WebDriver:GetCurrentChromeWindowHandle")
    end

    # Return array of window IDs currently opened
    def window_handles
      response = @transport.request("WebDriver:GetWindowHandles")
      response["value"].as_a.map(&.as_s)
    end

    # Switch to a specific window
    def switch_to_window(name)
      Log.debug { "(#{@id}) Switching to window #{name}" }
      @transport.request("WebDriver:SwitchToWindow", {name: name})
      nil
    end

    # Returns the current window position and size
    def window_rect
      response = @transport.request("WebDriver:GetWindowRect")
      WindowRect.from_json(response.params.to_json)
    end

    # Sets the size of the current window
    def set_window_rect(rect : WindowRect)
      Log.debug { "(#{@id}) Setting window rect to #{rect}" }
      @transport.request("WebDriver:SetWindowRect", {x: rect.x, y: rect.y, width: rect.width.floor, height: rect.height.floor})
      nil
    end

    # Maximizes the window
    def maximize_window
      Log.debug { "(#{@id}) Maximizing window" }
      @transport.request("WebDriver:MaximizeWindow")
      nil
    end

    # Minimizes the window
    def minimize_window
      Log.debug { "(#{@id}) Minimizing window" }
      @transport.request("WebDriver:MinimizeWindow")
      nil
    end

    # Makes the window fullscreen
    def fullscreen
      Log.debug { "(#{@id}) Making window fullscreen" }
      @transport.request("WebDriver:FullscreenWindow")
      nil
    end

    # Closes the current window
    def close_window
      Log.debug { "(#{@id}) Closing window" }
      @transport.request("WebDriver:CloseWindow")
      nil
    end

    # Get the screen orientation of the current browser.
    def orientation
      response = @transport.request("Marionette:GetScreenOrientation")
      response["value"].as_s
    end

    # Set the orientation
    def set_orientation(orientation)
      Log.debug { "(#{@id}) Setting orientation to #{orientation}" }
      @transport.request("Marionette:SetScreenOrientation", {orientation: orientation.to_s})
      nil
    end

    # Returns a class name representing the frame Marionette is currently acting on.
    def active_frame
      response = @transport.request("WebDriver:GetActiveFrame")
      response["value"].as_s?
    end

    # Switch to frame by `HTMLElement` or ID
    def switch_to_frame(frame : String | HTMLElement | Nil, focus = true)
      body = {focus: focus}

      if frame.is_a?(HTMLElement)
        Log.debug { "(#{@id}) Switching frame to element with id #{frame.id}" }
        body = body.merge({element: frame.id})
      elsif frame.is_a?(String)
        Log.debug { "(#{@id}) Switching frame to element with id #{frame}" }
        body = body.merge({id: frame})
      else
        Log.debug { "(#{@id}) Clearing frame" }
      end

      @transport.request("WebDriver:SwitchToFrame", body)
      nil
    end

    # Switch to frame by id or name
    def switch_to_frame(by : LocatorStrategy, value, focus = true)
      el = find_element(by, value)
      if el
        switch_to_frame(el, focus)
      end
    end

    # Switch to the parent frame
    def switch_to_parent_frame
      Log.debug { "(#{@id}) Switching to parent frame" }
      @transport.request("WebDriver:SwitchToParentFrame")
      nil
    end

    # Get all cookies
    def cookies
      response = @transport.request("WebDriver:GetCookies")
      cookies = response.params.as_a
      cookies.map do |cookie|
        expiry_date = cookie["expiry"]? ? Time.unix_ms(cookie["expiry"].as_i) : nil
        HTTP::Cookie.new(
          name: cookie["name"].as_s,
          value: cookie["value"].as_s,
          path: cookie["path"].as_s,
          expires: expiry_date,
          domain: cookie["domain"].as_s?,
          secure: cookie["secure"].as_bool? || false,
          http_only: cookie["httpOnly"].as_bool? || false
        )
      end
    end

    # Get a specific cookie by name
    def cookie(name)
      cookie = cookies.select { |cookie| cookie.name == name }
      cookie[0]?
    end

    # delete all cookies
    def delete_cookies
      @transport.request("WebDriver:DeleteAllCookies")
      Log.debug { "(#{@id}) All cookies removed" }
    end

    def reduce_memory_usage
      Log.debug { "(#{@id}) Reducing memory usage..." }
      navigate("about:memory")
      execute_script("doMMU();")
    end

    # Clear browser's history by emulating user actions in preferences
    # Navigate to about:preferences and execute script, that emulates
    # opening "Clear History" dialog and erasing all browser history.
    def clear_history
      Log.debug { "(#{@id}) Clearing history" }
      execute_script(%[window.stop();])
      navigate("about:preferences#privacy")
      sleep 0.5.seconds
      cnt = 0
      # Wait for the page to open. Logic stolen from WebDriver shard.
      loop do
        state = execute_script("return document.readyState;").try &.as_s?
        break if state == "complete"
        break if cnt >= 10
        cnt += 1
        sleep 0.1.seconds
      end
      Log.debug { "Document ready" }
      # Open "Clear History" dialog
      # execute_script(%[document.getElementById("clearHistoryButton").click();])
      # Wait for the dialog to open, check everything and click OK
      wait_and_click = <<-JS
        function waitForButton(attempts) {
          console.log("Waiting for button, attempts: " + attempts);
          if (attempts > 5) {
            console.log("button not found");
	          return;
	        }
          var btn = document.getElementById("clearHistoryButton");
          if (btn) {
            btn.click();
            setTimeout(waitForDialog, 300, 1);
            return;
          }
          setTimeout(waitForButton, 300, attempts + 1);
        }

        function waitForDialog(attempts) {
          console.log("Waiting for dialog, attempts: " + attempts);
          if (attempts > 5) {
            console.log("dialog not found");
            return;
          }
          var dlg = document.getElementsByClassName("dialogFrame")[0].contentDocument.getElementById("SanitizeDialog");
          if (dlg) {
            console.log("Found dialog" + dlg);
            // Find combo box at the beginning
            var combo = document.getElementsByClassName("dialogFrame")[0].contentDocument.getElementById("sanitizeDurationChoice");
            // Find all checkboxes
            var checks = dlg.getElementsByTagName("checkbox");
            // Find OK button
            var btn = dlg.getElementsByTagName("dialog")[0].shadowRoot.getElementsByAttribute("dlgtype", "accept")[0];
            console.log("Found combo" + combo + ", checkboxes:" + checks + " (" + checks.length + ")" +
                        ", button: " + btn);

            if (combo && checks && btn) {
              // Find the right value for "Clear Everything" option
              var clear_everything = combo.getElementsByAttribute("data-l10n-id", "clear-time-duration-value-everything")[0].value;
              combo.value = clear_everything;

              // Check all checkboxes
              for (const cb of checks) {
                cb.disabled = false;
                if (!cb.checked) {
                  cb.click();
                }
              }

              // click OK. This should be done in separate call to make sure
              // that combos and checks are changed.
              setTimeout(waitForClose, 300, 1);
              return;
            }
          }
          setTimeout(waitForDialog, 300, attempts + 1);
        }

        function waitForClose(attempts) {
          console.log("Waiting to close the dialog, attempts: " + attempts);
          if (attempts > 5) {
            console.log("button not found");
	          return;
	        }
          var dlg = document.getElementsByClassName("dialogFrame")[0].contentDocument.getElementById("SanitizeDialog");
          if (dlg) {
            var btn = dlg.getElementsByTagName("dialog")[0].shadowRoot.getElementsByAttribute("dlgtype", "accept")[0];
            if (btn) {
              console.log("Clicking the button");
              btn.disabled = false;
              btn.click();
              return;
            }
          }
          setTimeout(waitForClose, 300, attempts + 1);
        }

        waitForButton(1);
      JS
      execute_script(wait_and_click, timeout: 5.seconds, new_sandbox: true)
      # Timeout is necessary, because script never executes synchronously
      sleep 3.seconds
      Log.debug { "(#{@id}) History cleared" }
    end

    # Check if element is enabled
    def element_enabled?(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:IsElementEnabled", {id: id})
      response["value"].as_bool
    end

    # Check if the element is selected
    def element_selected?(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:IsElementSelected", {id: id})
      response["value"].as_bool
    end

    # Check if the element is displayed
    def element_displayed?(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:IsElementDisplayed", {id: id})
      response["value"].as_bool
    end

    # Gets the tag name of an element
    def element_tag_name(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:GetElementTagName", {id: id})
      response["value"].as_s
    end

    # Gets the text for an element
    def element_text(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:GetElementText", {id: id})
      response["value"].as_s
    end

    # Get an attribute for an element
    def element_attribute(el, name)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:GetElementAttribute", {id: id, name: name})
      response["value"].as_s
    end

    # Get a css property for an element
    def element_css_property(el, property)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:GetElementCSSValue", {id: id, propertyName: property})
      response["value"].as_s
    end

    # Get an element's rect
    def element_rect(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      response = @transport.request("WebDriver:GetElementRect", {id: id})
      if response
        ElementRect.new(
          response["x"].to_s.to_f,
          response["y"].to_s.to_f,
          response["width"].to_s.to_f,
          response["height"].to_s.to_f
        )
      end
    end

    # Simulate a click on a particular element
    def click_element(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      Log.debug { "(#{@id}) Clicking element with id #{id}" }
      @transport.request("WebDriver:ElementClick", {id: id})
      nil
    end

    # Sends keys to an element
    def send_keys_to_element(el, *keys)
      id = el.is_a?(HTMLElement) ? el.id : el
      Log.debug { "(#{@id}) Sending keys \"#{keys}\" to element with id #{id}" }
      @transport.request("WebDriver:ElementSendKeys", {id: id, text: keys.join})
      nil
    end

    # Clears a clearable element
    def clear_element(el)
      id = el.is_a?(HTMLElement) ? el.id : el
      Log.debug { "(#{@id}) Clearing element with id #{id}" }
      @transport.request("WebDriver:ElementClear", {id: id})
      nil
    end

    # Find elements using the indicated search strategy and
    # starting with a particular node.
    def find_elements(by : LocatorStrategy, value, start_node = nil)
      if start_node.nil? || start_node.empty?
        params = {using: by.to_s, value: value}
      else
        start_node = start_node.is_a?(HTMLElement) ? start_node.id : start_node
        params = {using: by.to_s, value: value, element: start_node}
      end

      response = @transport.request("WebDriver:FindElements", params)
      response.params.as_a.map(&.as_h.to_a).map do |a|
        HTMLElement.new(self, a[0][1].as_s)
      end
    rescue
      [] of HTMLElement
    end

    # Find a single element using the indicated search strategy and
    # starting with a particular node.
    def find_element(by : LocatorStrategy, value, start_node = nil)
      if start_node.nil? || start_node.empty?
        params = {using: by.to_s, value: value}
      else
        start_node = start_node.is_a?(HTMLElement) ? start_node.id : start_node
        params = {using: by.to_s, value: value, element: start_node}
      end

      response = @transport.request("WebDriver:FindElement", params)
      HTMLElement.new(self, response["value"].as_h.first[1].as_s)
    rescue
      nil
    end

    # Takes a screenshot of an element or the current frame.
    # Optionally also allows you to highlight specific elements.
    # Format can be `:hash`, :binary, or `:base64` (default).
    def take_screenshot(
      element = nil,
      highlights = nil,
      full = true,
      scroll = true,
      format = ScreenshotFormat::Binary
    )
      element = element.is_a?(HTMLElement) ? element.id : element
      highlights.try &.map do |el|
        el.is_a?(HTMLElement) ? el.id : el
      end

      params = {
        id:         element,
        highlights: highlights,
        full:       full,
        scroll:     scroll,
        hash:       format == :hash,
      }

      Log.debug { "(#{@id}) Taking screenshot" }

      response = @transport.request("WebDriver:TakeScreenshot", params)
      return unless response

      data = response["value"]?.try(&.as_s?)
      return unless data

      case format
      when ScreenshotFormat::Binary
        Base64.decode_string(data)
      else
        data
      end
    end

    # Captures and saves a screenshot. See `#take_screenshot`.
    def save_screenshot(file, **options)
      options = options.merge(format: ScreenshotFormat::Binary)
      data = take_screenshot(**options)
      raise "Failed to save screenshot" unless data
      Log.debug { "(#{@id}) Saving screenshot as #{file}" }
      File.write(file, data)
    end

    # Get the source for the current page.
    def page_source : String?
      response = @transport.request("WebDriver:GetPageSource")
      if response
        response["value"]?.try &.as_s?
      end
    end

    # Execute JS script. If `new_sandbox` is true (default) the global
    # variables from the last executed script will be preserved. The
    # result of executing the script is returned.
    def execute_script(script, args = nil, timeout : Time::Span = @timeout, new_sandbox = true)
      params = {
        scriptTimeout: timeout.total_milliseconds.to_i,
        script:        script,
        args:          args || [] of String,
        newSandbox:    new_sandbox,
      }

      Log.debug { "(#{@id}) Executing script" }

      response = @transport.request("WebDriver:ExecuteScript", params)
      response["value"]?
    end

    # Execute JS script asynchronously. See `#execute_script`.
    def execute_script_async(script, args = nil, timeout : Time::Span = @timeout, new_sandbox = true)
      params = {
        scriptTimeout: timeout.total_milliseconds.to_i,
        script:        script,
        args:          args || [] of String,
        newSandbox:    new_sandbox,
      }

      Log.debug { "(#{@id}) Executing async script" }

      response = @transport.request("WebDriver:ExecuteScriptAsync", params)
      response["value"]?
    end

    # Dismisses the dialog like clicking no/cancel.
    def dismiss_dialog
      Log.debug { "(#{@id}) Dismissing dialog" }
      @transport.request("WebDriver:DismissAlert")
      nil
    end

    # Accepts a dialog lick clicking ok/yes
    def accept_dialog
      Log.debug { "(#{@id}) Accepting dialog" }
      @transport.request("WebDriver:AcceptAlert")
      nil
    end

    # Gets the text from a dialog
    def text_from_dialog
      response = @transport.request("WebDriver:GetAlertText")
      if params = response.params.as_h?
        params["value"]?.try &.as_s?
      end
    end

    # Sends text to a dialog
    def send_keys_to_dialog(*keys)
      Log.debug { "(#{@id}) Sending keys #{keys} to dialog" }
      @transport.request("WebDriver:SendAlertText", {text: keys.join})
      nil
    end

    # Closes the browser
    def quit
      Log.debug { "(#{@id}) Quitting browser" }
      request_in_app_shutdown
    end

    # This will do an in-app restart of the browser.
    # NOTE: Not working yet
    def restart
      Log.debug { "(#{@id}) Restarting browser" }
      response = request_in_app_shutdown(["eRestart"])
      error = true
      while error
        begin
          @transport.request("Marionette:AcceptConnections", {value: true})
          error = false
        rescue
        end
      end
      response
    end

    private def request_in_app_shutdown(flags = [] of String)
      context = self.context

      # Block marionette from accepting new connections
      @transport.request("Marionette:AcceptConnections", {value: false})

      unless flags.any?(&.includes?("Quit"))
        flags.push("eForceQuit")
      end

      using_context(BrowserContext::Chrome) do
        script = <<-JAVASCRIPT
        Components.utils.import("resource://gre/modules/Services.jsm");
        let cancelQuit = Components.classes["@mozilla.org/supports-PRBool;1"]
            .createInstance(Components.interfaces.nsISupportsPRBool);
        Services.obs.notifyObservers(cancelQuit, "quit-application-requested", null);
        return cancelQuit.data;
        JAVASCRIPT
        canceled = execute_script(script)
        if canceled == "true"
          raise "Something cancelled the restart request"
        end
      end

      response = @transport.request("Marionette:Quit", {flags: flags})
      response["cause"].as_s
    end

    # Clear the user-defined value from the specified preference.
    def clear_pref(pref)
      Log.debug { "(#{@id}) Clearing preference '#{pref}'" }
      script = <<-JAVASCRIPT
      Components.utils.import("resource://gre/modules/Preferences.jsm");
      Preferences.reset(arguments[0]);
      JAVASCRIPT
      execute_script(script, [pref])
    end

    # Get's the value of a user-defined preference.
    def pref(pref, default_branch = false, value_type = "unspecified")
      script = <<-JAVASCRIPT
      Components.utils.import("resource://gre/modules/Preferences.jsm");

      let pref = arguments[0];
      let defaultBranch = arguments[1];
      let valueType = arguments[2];

      prefs = new Preferences({defaultBranch: defaultBranch});
      return prefs.get(pref, null, Components.interfaces[valueType]);
      JAVASCRIPT

      using_context(BrowserContext::Chrome) do
        execute_script(script, [pref, default_branch, value_type])
      end
    end

    # Set the value of the specified preference.
    def set_pref(pref, value, default_branch = false)
      Log.debug { "(#{@id}) Setting preference '#{pref}' to '#{value}'" }
      script = <<-JAVASCRIPT
      Components.utils.import("resource://gre/modules/Preferences.jsm");

      let pref = arguments[0];
      let value = arguments[1];
      let defaultBranch = arguments[2];

      prefs = new Preferences({defaultBranch: defaultBranch});
      prefs.set(pref, value);
      JAVASCRIPT

      using_context(BrowserContext::Chrome) do
        execute_script(script, [pref, value, default_branch])
      end
    end

    # Set the value of a list of preferences.
    def set_prefs(prefs, default_branch = false)
      prefs.map { |(pref, value)| set_pref(pref, value, default_branch) }
    end

    # Set preferences for code executed in block, and restores them on exit.
    def using_prefs(prefs, default_branch = false, &block)
      original_prefs = prefs.map { |(pref, _)| pref(pref, default_branch) }
      set_prefs(prefs, default_branch)
      output = with self yield self
      set_prefs(original_prefs, default_branch)
      output
    end

    # Create an instance of `Actions` and return it.
    def actions(type : Actions::ActionType, pointer_params = nil)
      id = "some_id"
      Actions.new(self, type, id, pointer_params)
    end

    # Performs an array of browser actions in order
    def perform_actions(actions)
      Log.debug { "(#{@id}) Preforming actions #{actions}" }
      @transport.request("WebDriver:PerformActions", {actions: actions})
    end

    def release_actions
      Log.debug { "(#{@id}) Releasing actions" }
      @transport.request("WebDriver:ReleaseActions")
    end

    def key(key)
      KEYS[key]
    end

    def last_request
      proxy.last_request
    end

    def last_response
      proxy.last_response
    end
  end
end
