module Marionette
  class Session
    include Logger

    property! service : Service?

    getter driver : WebDriver

    getter type : Type

    getter id : String

    def initialize(@driver : WebDriver, @id : String, @type : Type)
      at_exit { stop }
    end

    def local?
      !!@service
    end

    def remote?
      !local?
    end

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

    def w3c?
      @driver.w3c?
    end

    def status
      execute("Status")
    end

    def close
      execute("Quit", stop_on_exception: false)
    end

    def implicit_wait(time : Time::Span)
      if w3c?
        execute("SetTimeouts", {"implicit" => time.total_milliseconds.to_i})
      else
        execute("ImplicitWait", {"ms" => time.total_milliseconds.to_i})
      end
    end

    def script_timeout(time : Time::Span)
      if w3c?
        execute("SetTimeouts", {"script" => time.total_milliseconds.to_i})
      else
        execute("SetScriptTimeout", {"ms" => time.total_milliseconds.to_i})
      end
    end

    def page_load_timeout(time : Time::Span)
      begin
        execute("SetTimeouts", {"pageLoad" => time.total_milliseconds.to_i}, stop_on_exception: false)
      rescue ex : Error
        execute("SetTimeouts", {
          "type" => "page load",
          "ms" => time.total_milliseconds.to_i
        })
      end
    end

    def orientation
      if w3c?
        stop
        raise Error::GenericError.new("Orientation is only supported on non-W3C compatible drivers")
      else
        response = execute("GetScreenOrientation")
        Orientation.parse(response.upcase)
      end
    end

    def orientation=(origination : Orientation)
      if w3c?
        stop
        raise Error::GenericError.new("Orientation is only supported on non-W3C compatible drivers")
      else
        execute("SetScreenOrientation", {"orientation" => orientation.to_s})
      end
    end

    #  __        ___           _
    #  \ \      / (_)_ __   __| | _____      _____
    #   \ \ /\ / /| | '_ \ / _` |/ _ \ \ /\ / / __|
    #    \ V  V / | | | | | (_| | (_) \ V  V /\__ \
    #     \_/\_/  |_|_| |_|\__,_|\___/ \_/\_/ |___/
    #

    def current_window
      if w3c?
        handle = execute("W3CGetCurrentWindowHandle").as_s
      else
        handle = execute("GetCurrentWindowHandle").as_s
      end

      Window.new(self, handle, :window)
    end

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

    def switch_to_window(window : Window)
      execute("SwitchToWindow", {"handle" => window.handle})
    end

    def switch_to_window(handle : String)
      execute("SwitchToWindow", {"handle" => handle})
    end

    def new_window(type : Window::Type = :window)
      response = execute("NewWindow", {"type" => type.to_s.downcase})
      Window.new(
        self,
        response["handle"].as_s,
        Window::Type.parse(response["type"].as_s.downcase)
      )
    end

    def close_current_window
      execute("Close")
    end

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

    def navigate(to url : String | URI)
      execute("Get", {url: url.to_s})
    end

    def current_url
      execute("GetCurrentUrl").as_s
    end

    def back
      execute("GoBack")
    end

    def forward
      execute("GoForward")
    end

    def refresh
      execute("Refresh")
    end

    def title
      execute("GetTitle").as_s
    end

    #    ____            _    _
    #   / ___|___   ___ | | _(_) ___  ___
    #  | |   / _ \ / _ \| |/ / |/ _ \/ __|
    #  | |__| (_) | (_) |   <| |  __/\__ \
    #   \____\___/ \___/|_|\_\_|\___||___/
    #

    def get_cookie(cookie : HTTP::Cookie)
      get_cookie(cookie.name)
    end

    def get_cookie(name : String)
      begin
        value = execute("GetCookie", {"name" => name}, stop_on_exception: false)
        HTTP::Cookie.from_json(value.to_json)
      rescue ex : Error::NoSuchCookie
        Log.warn { "Cookie not found with name '#{name}'" }
        nil
      end
    end

    def delete_cookie(name : String)
      begin
        execute("DeleteCookie", {"name" => name}, stop_on_exception: false)
      rescue ex : Error::NoSuchCookie
        Log.warn { "Cookie not found with name '#{name}'" }
        nil
      end
    end

    def all_cookies
      cookies = execute("GetAllCookies")
      cookies.as_a.map { |c| HTTP::Cookie.from_json(c.to_json) }
    end

    def delete_all_cookies
      execute("DeleteAllCookies")
    end

    #   ____                                        _
    #  |  _ \  ___   ___ _   _ _ __ ___   ___ _ __ | |_
    #  | | | |/ _ \ / __| | | | '_ ` _ \ / _ \ '_ \| __|
    #  | |_| | (_) | (__| |_| | | | | | |  __/ | | | |_
    #  |____/ \___/ \___|\__,_|_| |_| |_|\___|_| |_|\__|
    #

    def page_source
      execute("GetPageSource").as_s
    end

    def execute_script(script, args = nil)
      params = {"script" => script, "args" => args || [] of String}
      if w3c?
        execute("W3CExecuteScript", params)
      else
        execute("ExecuteScript", params)
      end
    end

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

    def find_element(selector, strategy : LocationStrategy = :css)
      begin
        find_element!(selector, strategy)
      rescue ex : Error::NoSuchElement
        nil
      end
    end

    def find_element!(selector, strategy : LocationStrategy = :css)
      response = execute("FindElement", Utils.selector_params(selector, strategy, w3c?), stop_on_exception: false)
      id = response.as_h.values[0].as_s
      Element.new(self, id)
    end

    def find_elements(selector, strategy : LocationStrategy = :css)
      begin
        response = execute("FindElements", Utils.selector_params(selector, strategy, w3c?), stop_on_exception: false)
        response.as_a.map do |v|
          id = v.as_h.values[0].as_s
          Element.new(self, id)
        end
      rescue ex : Error::NoSuchElement
        [] of Element
      end
    end

    def find_element_child(element, selector, strategy : LocationStrategy = :css)
      begin
        find_element_child!(element, selector, strategy)
      rescue ex : Error::NoSuchElement
        nil
      end
    end

    def find_element_child!(element, selector, strategy : LocationStrategy = :css)
      element_id = element.is_a?(Element) ? element.id : element
      params = Utils.selector_params(selector, strategy, w3c?)
      params["$elementId"] = element_id

      response = execute("FindChildElement", params, stop_on_exception: false)
      id = response.as_h.values[0].as_s
      Element.new(self, id)
    end

    def find_element_children(element, selector, strategy : LocationStrategy = :css)
      element_id = element.is_a?(Element) ? element.id : element
      params = Utils.selector_params(selector, strategy, w3c?)
      params["$elementId"] = element_id
      begin
        response = execute("FindChildElements", params, stop_on_exception: false)
        response.as_a.map do |v|
          id = v.as_h.values[0].as_s
          Element.new(self, id)
        end
      rescue ex : Error::NoSuchElement
        [] of Element
      end
    end

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

    def switch_to_frame(frame : Element)
      execute("SwitchToFrame", {"id" => frame})
    end

    def switch_to_frame(frame_id : Int)
      execute("SwitchToFrame", {"id" => frame_id})
    end

    def switch_to_parent_frame
      execute("SwitchToParentFrame")
    end

    def leave_frame
      execute("SwitchToFrame", {"id" => nil})
    end

    #      _    _           _
    #     / \  | | ___ _ __| |_ ___
    #    / _ \ | |/ _ \ '__| __/ __|
    #   / ___ \| |  __/ |  | |_\__ \
    #  /_/   \_\_|\___|_|   \__|___/
    #

    def dismiss_alert
      if w3c?
        execute("W3CDismissAlert")
      else
        execute("DismissAlert")
      end
    end

    def accept_alert
      if w3c?
        execute("W3CAcceptAlert")
      else
        execute("AcceptAlert")
      end
    end

    def alert_text
      if w3c?
        execute("W3CGetAlertText")
      else
        execute("GetAlertText")
      end
    end

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

    def take_screenshot
      execute("Screenshot")
    end

    def take_screenshot(element_id : String, scroll = true)
      execute("ElementScreenshot", {"$elementId" => element_id, "scroll" => scroll})
    end

    def save_screenshot(path, element_id = nil, scroll = true)
      b64 = element_id ? take_screenshot(element_id, scroll) : take_screenshot
      data = Base64.decode(b64.as_s)
      File.write(path, data)
    end

    #      _        _   _
    #     / \   ___| |_(_) ___  _ __  ___
    #    / _ \ / __| __| |/ _ \| '_ \/ __|
    #   / ___ \ (__| |_| | (_) | | | \__ \
    #  /_/   \_\___|\__|_|\___/|_| |_|___/
    #

    def clear_actions
      execute("W3CClearActions")
    end

    def actions(&block)
      builder = ActionBuilder.new(session: self)
      with builder yield builder
      builder
    end

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

    def context
      assert_browser(:firefox)
      execute("GetContext")
    end

    def context=(context : String)
      assert_browser(:firefox)
      execute("SetContext", {"context" => context})
    end

    def install_addon(path : String, temporary = false)
      assert_browser(:firefox)
      execute("InstallAddon", {"path" => path, "temporary" => temporary})
    end

    def uninstall_addon(id : String)
      assert_browser(:firefox)
      execute("UninstallAddon", {"id" => id})
    end

    def full_page_screenshot
      assert_browser(:firefox)
      result = execute("FullPageScreenshot").as_s
      Base64.decode(result)
    end

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

    def launch_app(app_id : String)
      assert_browser(:chrome)
      execute("LaunchApp", {"id" => app_id})
    end

    def network_conditions
      assert_browser(:chrome)
      response = execute("GetNetworkConditions")
      NetworkConditions.from_json(response.to_json)
    end

    def network_conditions=(conditions : NetworkConditions)
      assert_browser(:chrome)
      execute("SetNetworkConditions", network_conditions.to_json)
    end

    def sinks
      assert_browser(:chrome)
      execute("GetSinks").as_a.map(&.as_s)
    end

    def sink=(sink_name : String)
      assert_browser(:chrome)
      execute("SetSinkToUse", {"sinkName" => sink_name})
    end

    def start_tab_mirroring(sink_name : String)
      assert_browser(:chrome)
      execute("StartTabMirroring", {"sinkName" => sink_name})
    end

    def stop_casting(sink_name : String)
      assert_browser(:chrome)
      execute("StopCasting", {"sinkName" => sink_name})
    end

    def issue_message
      assert_browser(:chrome)
      execute("GetIssueMessage").as_s
    end

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

    def perimissions
      assert_browser(:safari)
      response = execute("GetPermissions")
      Hash(String, Bool).from_json(response["permissions"].to_json)
    end

    def permissions=(perms : Hash(String, Bool))
      assert_browser(:safari)
      response = execute("SetPermissions", {"permissions" => perms})
      Hash(String, Bool).from_json(response["permissions"].to_json)
    end

    def set_permission(key : String, value : Bool)
      assert_browser(:safari)
      permissions = {"key" => value}
    end

    def debug
      assert_browser(:safari)
      execute("AttachDebugger")
      execute_script("debugger;")
    end

    def execute(command, params = {} of String => String, stop_on_exception = true)
      new_params = {} of String => JSON::Any

      new_params["$sessionId"] = JSON::Any.new(@id)
      params.each do |k, v|
        new_params[k.to_s] = JSON.parse(v.to_json)
      end

      begin
        result = @driver.execute(command, new_params)
      rescue ex
        if stop_on_exception
          Log.fatal(exception: ex) {
            "Unexpected exception caught while executing command #{command}. Closing session."
          }
          return stop
        else
          raise ex
        end
      end

      result["value"]
    end

    def assert_browser(browser : Browser)
      if service.browser != browser
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
