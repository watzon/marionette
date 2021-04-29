module Marionette
  class Session
    include Logger

    property! service : Service?

    getter driver : WebDriver

    getter type : Type

    getter id : String

    getter? w3c : Bool

    getter capabilities : Hash(String, JSON::Any)

    # :nodoc:
    def initialize(@driver : WebDriver,
                   @id : String,
                   @type : Type,
                   @capabilities : Hash(String, JSON::Any),
                   @service = nil,
                   @w3c = false)
      at_exit do
        if (svc = @service) && !svc.closed?
          stop
        end
      end
    end

    # Start a new Session using the given `driver` and `type`. You can pass in any
    # `capabilities` you want here, and they'll be merged with the browser's
    # desired capabilities.
    def self.start(driver : WebDriver,
                   type : Type,
                   capabilities = {} of String => String,
                   service = nil)
      # Merge user capabilities with the desired capabilities
      # for the given browser.
      caps = driver.browser.desired_capabilities
      caps = capabilities.merge(caps)

      params = {
        "capabilities"         => Utils.to_w3c_caps(caps),
        "desired_capabilities" => caps,
      }

      # Create a new session using the requested capabilities
      response = driver.execute("NewSession", params)
      response = response["value"] unless response["sessionId"]?

      # If we were given a sessionId we're golden
      if session_id = response["sessionId"]?
        capabilities = response["value"]? || response["capabilities"]
        w3c = response["status"]?.nil?

        new(
          driver,
          id: session_id.as_s,
          type: type,
          capabilities: capabilities.as_h,
          service: service,
          w3c: w3c
        )
      else
        raise "Session creation failed"
      end
    end

    # Returns true if this is a local session.
    def local?
      !!@service
    end

    # Returns true if this is a remote session.
    def remote?
      !local?
    end

    # Stops the current session by closing it and then closing the
    # WebDriver process.
    def stop
      result = close
      case @type
      in Type::Local
        service.stop
      in Type::Remote
        # Do nothing
      end
      result
    end

    #   ____                _
    #  / ___|  ___  ___ ___(_) ___  _ __
    #  \___ \ / _ \/ __/ __| |/ _ \| '_ \
    #   ___) |  __/\__ \__ \ | (_) | | | |
    #  |____/ \___||___/___/_|\___/|_| |_|
    #

    # Return the status of the current driver as a JSON object.
    def status
      execute("Status")
    end

    # Close the current session.
    def close
      execute("Quit")
    end

    # Add an implicit wait that will occur before calls are made in a newly opened page.
    def implicit_wait(time : Time::Span)
      if w3c?
        execute("SetTimeouts", {"implicit" => time.total_milliseconds.to_i})
      else
        execute("ImplicitWait", {"ms" => time.total_milliseconds.to_i})
      end
    end

    # Add a timeout for script execution. Scripts that take longer than the given amount
    # of time to execute will throw as `Error::TimeoutError`.
    def script_timeout(time : Time::Span)
      if w3c?
        execute("SetTimeouts", {"script" => time.total_milliseconds.to_i})
      else
        execute("SetScriptTimeout", {"ms" => time.total_milliseconds.to_i})
      end
    end

    # Add a timeout for page loads. Pages that take longer than the given amount of time to load
    # will throw an `Error::TimeoutError`.
    def page_load_timeout(time : Time::Span)
      begin
        execute("SetTimeouts", {"pageLoad" => time.total_milliseconds.to_i})
      rescue ex : Error
        execute("SetTimeouts", {
          "type" => "page load",
          "ms"   => time.total_milliseconds.to_i,
        })
      end
    end

    # Get the orientation of the current driver.
    #
    # NOTE: only available on non-W3C compatible drivers.
    def orientation
      if w3c?
        stop
        raise Error::GenericError.new("Orientation is only supported on non-W3C compatible drivers")
      else
        response = execute("GetScreenOrientation")
        Orientation.parse(response.upcase)
      end
    end

    # Set the orientation of the current driver.
    #
    # NOTE: only available on non-W3C compatible drivers.
    def orientation=(origination : Orientation)
      if w3c?
        stop
        raise Error::GenericError.new("Orientation is only supported on non-W3C compatible drivers")
      else
        execute("SetScreenOrientation", {"orientation" => orientation.to_s})
      end
    end

    def log(log_type : String)
      response = execute("GetLog", {"type" => log_type})
      logs = Array(LogItem).from_json(response.to_json)
    end

    def log_types
      execute("GetAvailableLogTypes")
    end

    #  __        ___           _
    #  \ \      / (_)_ __   __| | _____      _____
    #   \ \ /\ / /| | '_ \ / _` |/ _ \ \ /\ / / __|
    #    \ V  V / | | | | | (_| | (_) \ V  V /\__ \
    #     \_/\_/  |_|_| |_|\__,_|\___/ \_/\_/ |___/
    #

    # Return the current `Window`.
    def current_window
      if w3c?
        handle = execute("W3CGetCurrentWindowHandle").as_s
      else
        handle = execute("GetCurrentWindowHandle").as_s
      end

      Window.new(self, handle, :window)
    end

    # Return an array of all opened `Window`s.
    def windows
      if w3c?
        handles = execute("W3CGetWindowHandles").as_a.map(&.as_s)
      else
        handles = execute("GetWindowHandles").as_a.map(&.as_s)
      end

      handles.map do |handle|
        Window.new(self, handle, :window)
      end
    end

    # Switch to a given `Window`.
    def switch_to_window(window : Window)
      execute("SwitchToWindow", {"handle" => window.handle})
    end

    # Switch to a given `Window` using its handle.
    def switch_to_window(handle : String)
      execute("SwitchToWindow", {"handle" => handle})
    end

    # Create a new `Window`. The window will not be switched to
    # automatically.
    def new_window(type : Window::Type = :window)
      response = execute("NewWindow", {"type" => type.to_s.downcase})
      Window.new(
        self,
        response["handle"].as_s,
        Window::Type.parse(response["type"].as_s.downcase)
      )
    end

    # Close the current `Window`.
    def close_current_window
      execute("Close")
    end

    # Close the given `Window`.
    def close_window(window : Window)
      switch_to_window(window)
      close_current_window
    end

    #   _   _             _             _   _
    #  | \ | | __ ___   _(_) __ _  __ _| |_(_) ___  _ __
    #  |  \| |/ _` \ \ / / |/ _` |/ _` | __| |/ _ \| '_ \
    #  | |\  | (_| |\ V /| | (_| | (_| | |_| | (_) | | | |
    #  |_| \_|\__,_| \_/ |_|\__, |\__,_|\__|_|\___/|_| |_|
    #                       |___/

    # Go to the given URL.
    def navigate(to url : String | URI)
      execute("Get", {url: url.to_s})
    end

    # Get the URL of the current page.
    def current_url
      execute("GetCurrentUrl").as_s
    end

    # Go back in history.
    def back
      execute("GoBack")
    end

    # Go forward in history.
    def forward
      execute("GoForward")
    end

    # Refresh the current page.
    def refresh
      execute("Refresh")
    end

    # Return the title of the current page.
    def title
      execute("GetTitle").as_s
    end

    #    ____            _    _
    #   / ___|___   ___ | | _(_) ___  ___
    #  | |   / _ \ / _ \| |/ / |/ _ \/ __|
    #  | |__| (_) | (_) |   <| |  __/\__ \
    #   \____\___/ \___/|_|\_\_|\___||___/
    #

    # Get a browser cookie using an `HTTP::Cookie` instance.
    def get_cookie(cookie : HTTP::Cookie)
      get_cookie(cookie.name)
    end

    # Get the cookie with the specified name. Returns `nil` if no cookie was found.
    def get_cookie(name : String)
      value = execute("GetCookie", {"name" => name})
      HTTP::Cookie.from_json(value.to_json)
    end

    # Delete the cookie with the specified name.
    def delete_cookie(name : String)
      execute("DeleteCookie", {"name" => name})
    end

    # Add a cookie with the given name, value, and other options.
    def add_cookie(name : String,
                   value : String,
                   path : String = "/",
                   domain : String? = nil,
                   secure : Bool = false,
                   http_only : Bool = false,
                   expires : Time | Int32 | Nil = nil,
                   same_site : HTTP::Cookie::SameSite? = nil)
      cookie = {
        "name"     => name,
        "value"    => value,
        "path"     => path,
        "domain"   => domain,
        "secure"   => secure,
        "httpOnly" => http_only,
        "expiry"   => expires.is_a?(Time) ? expires.to_unix : expires,
        "sameSite" => same_site.to_s,
      }
      execute("AddCookie", {
        "cookie" => cookie.compact,
      })
    end

    # Add a cookie from an `HTTP::Cookie` instance.
    def add_cookie(cookie c : HTTP::Cookie)
      add_cookie(c.name, c.value, c.path, c.domain, c.secure, c.http_only, c.expires, c.same_site)
    end

    # Add multiple cookies from an `HTTP::Cookies` instance.
    def add_cookies(cookies : HTTP::Cookies)
      cookies.each do |cookie|
        add_cookie(cookie)
      end
    end

    # Return all cookies collected so far as an `Array(HTTP::Cookie)`.
    def all_cookies
      cookies = execute("GetAllCookies")
      cookies.as_a.map { |c| HTTP::Cookie.from_json(c.to_json) }
    end

    # Delete all collected cookies
    def delete_all_cookies
      execute("DeleteAllCookies")
    end

    #   ____                                        _
    #  |  _ \  ___   ___ _   _ _ __ ___   ___ _ __ | |_
    #  | | | |/ _ \ / __| | | | '_ ` _ \ / _ \ '_ \| __|
    #  | |_| | (_) | (__| |_| | | | | | |  __/ | | | |_
    #  |____/ \___/ \___|\__,_|_| |_| |_|\___|_| |_|\__|
    #

    # Return the source of the given page. For most pages this will be
    # HTML markup.
    def page_source
      execute("GetPageSource").as_s
    end

    # Execute arbitrary JavaScript in the context of the given document. Any args to be passed
    # into the script should be provided as an array.
    #
    # For now the result is returned as raw JSON.
    def execute_script(script, args = nil)
      params = {"script" => script, "args" => args || [] of String}
      if w3c?
        execute("W3CExecuteScript", params)
      else
        execute("ExecuteScript", params)
      end
    end

    # Execute arbitrary JavaScript in the context of the given document. Any args to be passed
    # into the script should be provided as an array.
    #
    # This is an async process and does not return a result.
    def execute_script_async(script, args = nil)
      params = {"script" => script, "args" => args || [] of String}
      if w3c?
        execute("W3CExecuteScriptAsync", params)
      else
        execute("ExecuteAsyncScript", params)
      end
    end

    #   _____ _                           _
    #  | ____| | ___ _ __ ___   ___ _ __ | |_ ___
    #  |  _| | |/ _ \ '_ ` _ \ / _ \ '_ \| __/ __|
    #  | |___| |  __/ | | | | |  __/ | | | |_\__ \
    #  |_____|_|\___|_| |_| |_|\___|_| |_|\__|___/
    #

    # Returns the element with focus, or the page Body if nothing has focus.
    def active_element
      if w3c?
        response = execute("W3CGetActiveElement")
      else
        response = execute("GetActiveElement")
      end

      Element.from_json(response.to_json)
    end

    # Find an element using the given `selector`. The `strategy` can be any
    # `LocationStrategy`. Default is `LocationStrategy::Css`. Returns
    # `nil` if no element with the given selector was found.
    def find_element(selector, strategy : LocationStrategy = :css)
      begin
        find_element!(selector, strategy)
      rescue ex : Error::NoSuchElement
        nil
      end
    end

    # Find an element using the given `selector`. The `strategy` can be any
    # `LocationStrategy`. Default is `LocationStrategy::Css`. Raises an
    # exception if no element with the given selector was found.
    def find_element!(selector, strategy : LocationStrategy = :css)
      response = execute("FindElement", Utils.selector_params(selector, strategy, w3c?))
      id = response.as_h.values[0].as_s
      Element.new(self, id)
    end

    # Find multiple elements with the given selector and return them as
    # an array.
    def find_elements(selector, strategy : LocationStrategy = :css)
      begin
        response = execute("FindElements", Utils.selector_params(selector, strategy, w3c?))
        response.as_a.map do |v|
          id = v.as_h.values[0].as_s
          Element.new(self, id)
        end
      rescue ex : Error::NoSuchElement
        [] of Element
      end
    end

    # Find a child of the given element. Returns `nil` if no element with the given
    # selector was found.
    def find_element_child(element, selector, strategy : LocationStrategy = :css)
      find_element_child!(element, selector, strategy)
    end

    # Find a child of the given element. Raises an exception if no element with the
    # given selector was found.
    def find_element_child!(element, selector, strategy : LocationStrategy = :css)
      element_id = element.is_a?(Element) ? element.id : element
      params = Utils.selector_params(selector, strategy, w3c?)
      params["$elementId"] = element_id

      response = execute("FindChildElement", params)
      id = response.as_h.values[0].as_s
      Element.new(self, id)
    end

    # Find multiple children of the given `element` with the given selector and
    # return them as an array.
    def find_element_children(element, selector, strategy : LocationStrategy = :css)
      element_id = element.is_a?(Element) ? element.id : element
      params = Utils.selector_params(selector, strategy, w3c?)
      params["$elementId"] = element_id
      response = execute("FindChildElements", params)
      response.as_a.map do |v|
        id = v.as_h.values[0].as_s
        Element.new(self, id)
      end
    end

    # Wait the given amount of time for an element to be available.
    # If no element is found an exception will be raised.
    def wait_for_element(selector : String,
                         strategy : LocationStrategy = :css,
                         timeout = 3.seconds,
                         poll_time = 50.milliseconds,
                         &block)
      start_time = Time.monotonic

      loop do
        begin
          if element = find_element(selector, strategy)
            return yield element
          end
        rescue ex
        end
        if Time.monotonic - start_time > timeout
          stop
          raise Error::GenericError.new("Waiting for element '#{selector}' failed")
        end

        sleep poll_time
      end
    end

    # :ditto:
    def wait_for_element(selector : String,
                         strategy : LocationStrategy = :css,
                         timeout = 3.seconds,
                         poll_time = 50.milliseconds)
      wait_for_element(selector, strategy, timeout, poll_time) { |e| e }
    end

    # Wait the given amount of time for elements to be available.
    # If no element is found an exception will be raised.
    def wait_for_elements(selector : String,
                          strategy : LocationStrategy = :css,
                          timeout = 3.seconds,
                          poll_time = 50.milliseconds,
                          &block)
      start_time = Time.monotonic

      loop do
        begin
          if elements = find_elements(selector, strategy)
            return yield elements
          end
        rescue ex
        end
        if Time.monotonic - start_time > timeout
          stop
          raise Error::GenericError.new("Waiting for elements '#{selector}' failed")
        end

        sleep poll_time
      end
    end

    # :ditto:
    def wait_for_elements(selector : String,
                          strategy : LocationStrategy = :css,
                          timeout = 3.seconds,
                          poll_time = 50.milliseconds,
                          &block)
      wait_for_elements(selector, strategy, timeout, poll_time) { |e| e }
    end

    # Switch the context to the given `frame` or `iframe` element.
    def switch_to_frame(frame : Element)
      execute("SwitchToFrame", {"id" => frame})
    end

    # Switch the context to the parent of the given `frame` or `iframe` element.
    def switch_to_parent_frame
      execute("SwitchToParentFrame")
    end

    # Leave the current frame context and return to the default context.
    def leave_frame
      execute("SwitchToFrame", {"id" => nil})
    end

    #      _    _           _
    #     / \  | | ___ _ __| |_ ___
    #    / _ \ | |/ _ \ '__| __/ __|
    #   / ___ \| |  __/ |  | |_\__ \
    #  /_/   \_\_|\___|_|   \__|___/
    #

    # Dismiss an active alert. For confirmation boxes this is the same as
    # clicking the "Cancel" button.
    def dismiss_alert
      if w3c?
        execute("W3CDismissAlert")
      else
        execute("DismissAlert")
      end
    end

    # Accept an active alert. For confirmation boxes this is the same as
    # clicking the "Ok" button.
    def accept_alert
      if w3c?
        execute("W3CAcceptAlert")
      else
        execute("AcceptAlert")
      end
    end

    # Returns the text of the active alert dialog.
    def alert_text
      if w3c?
        execute("W3CGetAlertText")
      else
        execute("GetAlertText")
      end
    end

    # Sets the text box content for alert dialogs that have one.
    def alert_value=(value)
      if w3c?
        execute("W3CSetAlertValue", {"value" => value.to_s, "text" => value.to_s})
      else
        execute("SetAlertValue", {"text" => value.to_s})
      end
    end

    #   ____                               _           _
    #  / ___|  ___ _ __ ___  ___ _ __  ___| |__   ___ | |_ ___
    #  \___ \ / __| '__/ _ \/ _ \ '_ \/ __| '_ \ / _ \| __/ __|
    #   ___) | (__| | |  __/  __/ | | \__ \ | | | (_) | |_\__ \
    #  |____/ \___|_|  \___|\___|_| |_|___/_| |_|\___/ \__|___/
    #

    # Take a screenshot of the current visible portion of the screen. The PNG
    # is returned as a Base64 encoded string.
    def take_screenshot
      execute("Screenshot").as_s
    end

    # Take a screenshot of the element with the given `element_id`. If `scroll` is
    # set to `true` the element will be scrolled to before taking the screenshot.
    #
    # The PNG data is returned as a Base64 encoded string.
    def take_screenshot(element_id : String, scroll = true)
      execute("ElementScreenshot", {"$elementId" => element_id, "scroll" => scroll}).as_s
    end

    # Take a screenshot and save it as a PNG at the given `path`. If `scroll` is
    # set to `true` the element will be scrolled to before taking the screenshot.
    def save_screenshot(path, element_id = nil, scroll = true)
      b64 = element_id ? take_screenshot(element_id, scroll) : take_screenshot
      data = Base64.decode(b64)
      File.write(path, data)
    end

    #      _        _   _
    #     / \   ___| |_(_) ___  _ __  ___
    #    / _ \ / __| __| |/ _ \| '_ \/ __|
    #   / ___ \ (__| |_| | (_) | | | \__ \
    #  /_/   \_\___|\__|_|\___/|_| |_|___/
    #

    # Clears actions that are already stored on the remote end.
    def clear_actions
      execute("W3CClearActions")
    end

    # Creates a new `ActionBuilder` instance and passes it to the block.
    # Given actions are not performed on block exit, so you will need
    # to call `ActionBuilder#perform` eventually.
    def actions(&block)
      builder = ActionBuilder.new(session: self)
      with builder yield builder
      builder
    end

    # Creates a new `ActionBuilder` instance and passes it to the block.
    # Actions are performed immediately upon block exit.
    #
    # Set `debug_mouse_move` to `true` to get visual indicators
    # on screen when the mouse changes location.
    def perform_actions(debug_mouse_move = false, &block)
      builder = ActionBuilder.new(session: self)
      with builder yield builder
      builder.perform(debug_mouse_move)
    end

    #   _____ _           __
    #  |  ___(_)_ __ ___ / _| _____  __
    #  | |_  | | '__/ _ \ |_ / _ \ \/ /
    #  |  _| | | | |  __/  _| (_) >  <
    #  |_|   |_|_|  \___|_|  \___/_/\_\
    #

    # Get the current browser context.
    #
    # NOTE: Available for Firefox only.
    def context
      assert_browser(:firefox)
      execute("GetContext")
    end

    # Set the current browser context.
    #
    # NOTE: Available for Firefox only.
    def context=(context : String)
      assert_browser(:firefox)
      execute("SetContext", {"context" => context})
    end

    # Install an addon from the given path. If `temporary` is set
    # to `true` this addon will only be installed for the
    # current session.
    #
    # NOTE: Available for Firefox only.
    def install_addon(path : String, temporary = false)
      assert_browser(:firefox)
      execute("InstallAddon", {"path" => path, "temporary" => temporary})
    end

    # Uninstall an addon using its `id`.
    #
    # NOTE: Available for Firefox only.
    def uninstall_addon(id : String)
      assert_browser(:firefox)
      execute("UninstallAddon", {"id" => id})
    end

    # Takes a full screen screenshot and return it as
    # a Base64 encoded PNG string.
    #
    # NOTE: Available for Firefox only.
    def full_page_screenshot
      assert_browser(:firefox)
      execute("FullPageScreenshot").as_s
    end

    # Take a fullscreen screenshot and save it to the
    # given `path` as a PNG image.
    #
    # NOTE: Available for Firefox only.
    def save_full_page_screenshot(path : String)
      assert_browser(:firefox)
      b64 = full_page_screenshot
      File.write(path, b64)
    end

    #    ____ _
    #   / ___| |__  _ __ ___  _ __ ___   ___
    #  | |   | '_ \| '__/ _ \| '_ ` _ \ / _ \
    #  | |___| | | | | | (_) | | | | | |  __/
    #   \____|_| |_|_|  \___/|_| |_| |_|\___|
    #

    # Launch a Chrome app using its `id`.
    #
    # NOTE: Available for Chrome/Chromium only.
    def launch_app(app_id : String)
      assert_browser(:chrome)
      execute("LaunchApp", {"id" => app_id})
    end

    # Return the set network conditions as a `NetworkConditions`
    # object. This will raise if network conditions haven't
    # been set already.
    #
    # NOTE: Available for Chrome/Chromium only.
    def network_conditions
      assert_browser(:chrome)
      response = execute("GetNetworkConditions")
      NetworkConditions.from_json(response.to_json)
    end

    # Set the network conditions.
    #
    # NOTE: Available for Chrome/Chromium only.
    def network_conditions=(conditions : NetworkConditions)
      assert_browser(:chrome)
      execute("SetNetworkConditions", network_conditions.to_json)
    end

    # Get a list of sinks for casting.
    #
    # NOTE: Available for Chrome/Chromium only.
    def sinks
      assert_browser(:chrome)
      execute("GetSinks").as_a.map(&.as_s)
    end

    # Set the current casting sink.
    #
    # NOTE: Available for Chrome/Chromium only.
    def sink=(sink_name : String)
      assert_browser(:chrome)
      execute("SetSinkToUse", {"sinkName" => sink_name})
    end

    # Start mirroring the current tab using the given sink.
    #
    # NOTE: Available for Chrome/Chromium only.
    def start_tab_mirroring(sink_name : String)
      assert_browser(:chrome)
      execute("StartTabMirroring", {"sinkName" => sink_name})
    end

    # Stop casting to the current sink.
    #
    # NOTE: Available for Chrome/Chromium only.
    def stop_casting(sink_name : String)
      assert_browser(:chrome)
      execute("StopCasting", {"sinkName" => sink_name})
    end

    # Get the issue message for the current cast context.
    #
    # NOTE: Available for Chrome/Chromium only.
    def issue_message
      assert_browser(:chrome)
      execute("GetIssueMessage").as_s
    end

    # Execute a CDP (Chrome DevTools Protocol) command. See the
    # [API documentation](https://chromedevtools.github.io/devtools-protocol/)
    # for information on acceptable commands.
    #
    # NOTE: Available for Chrome/Chromium only.
    def execute_cdp_command(cmd : String, args = {} of String => String)
      assert_browser(:chrome)
      execute("ExecuteCdpCommand", {"cmd" => cmd, "params" => args})
    end

    #   ____         __            _
    #  / ___|  __ _ / _| __ _ _ __(_)
    #  \___ \ / _` | |_ / _` | '__| |
    #   ___) | (_| |  _| (_| | |  | |
    #  |____/ \__,_|_|  \__,_|_|  |_|
    #

    # Get the currently set Safari permisisons.
    #
    # NOTE: Available for Safari only.
    def permissions
      assert_browser(:safari)
      response = execute("GetPermissions")
      Hash(String, Bool).from_json(response["permissions"].to_json)
    end

    # Set Safari permissions.
    #
    # NOTE: Available for Chrome/Chromium only.
    def permissions=(perms : Hash(String, Bool))
      assert_browser(:safari)
      response = execute("SetPermissions", {"permissions" => perms})
      Hash(String, Bool).from_json(response["permissions"].to_json)
    end

    # Set a single Safari permission.
    #
    # NOTE: Available for Chrome/Chromium only.
    def set_permission(key : String, value : Bool)
      assert_browser(:safari)
      permissions = {"key" => value}
    end

    # Enable and attach the Safari debugger.
    #
    # NOTE: Available for Chrome/Chromium only.
    def debug
      assert_browser(:safari)
      execute("AttachDebugger")
      execute_script("debugger;")
    end

    # Execute an arbitrary command with the given permissions. See `Commands`
    # for all available commands.
    def execute(command, params = {} of String => String)
      new_params = {} of String => JSON::Any

      new_params["$sessionId"] = JSON::Any.new(@id)
      params.each do |k, v|
        new_params[k.to_s] = JSON.parse(v.to_json)
      end

      result = @driver.execute(command, new_params)
      result["value"]
    end

    private def assert_browser(browser : Browser)
      if driver.browser != browser
        raise Error::UnknownMethod.new("Command is valid for #{browser} only.")
      end
    end

    enum Type
      Local
      Remote
    end

    enum Orientation
      Landscape
      Portrait

      def to_s(io)
        io << super.downcase
      end
    end

    record NetworkConditions,
      offline : Bool,
      latency : Int32,
      download_throughput : Int32,
      upload_throughput : Int32 do
      include JSON::Serializable
    end
  end
end
