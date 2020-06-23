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

    def w3c?
      @driver.w3c?
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

    def status
      execute("Status")
    end

    def close
      execute("Quit", stop_on_exception: false)
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

    def find_element(selector, strategy : LocationStrategy = :css_selector)
      begin
        response = execute("FindElement", Utils.selector_params(selector, strategy, w3c?), stop_on_exception: false)
        id = response.as_h.values[0].as_s
        Element.new(self, id)
      rescue ex
        nil
      end
    end

    def find_elements(selector, strategy : LocationStrategy = :css_selector)
      begin
        response = execute("FindElements", Utils.selector_params(selector, strategy, w3c?), stop_on_exception: false)
        response.as_a.map do |v|
          id = v.as_h.values[0].as_s
          Element.new(self, id)
        end
      rescue ex
        nil
      end
    end

    def find_element_child(element, selector, strategy : LocationStrategy = :css_selector)
      element_id = element.is_a?(Element) ? element.id : element
      params = Utils.selector_params(selector, strategy, w3c?)
      params["$elementId"] = element_id
      begin
        response = execute("FindChildElement", params, stop_on_exception: false)
        id = response.as_h.values[0].as_s
        Element.new(self, id)
      rescue ex
        nil
      end
    end

    def find_element_children(element, selector, strategy : LocationStrategy = :css_selector)
      element_id = element.is_a?(Element) ? element.id : element
      params = Utils.selector_params(selector, strategy, w3c?)
      params["$elementId"] = element_id
      begin
        response = execute("FindChildElements", params, stop_on_exception: false)
        response.as_a.map do |v|
          id = v.as_h.values[0].as_s
          Element.new(self, id)
        end
      rescue ex
        nil
      end
    end

    def wait_for_element(selector : String, strategy : LocationStrategy = :css_selector, timeout = 10.seconds, poll_time = 50.milliseconds, &block)
      wait_time = 0.0
      loop do
        begin
          if element = find_element(selector, strategy)
            return yield element
          end
        rescue ex
        end
        sleep poll_time
        wait_time += poll_time.total_milliseconds

        if wait_time > timeout.total_milliseconds
          stop
          raise "Waiting for element '#{selector}' failed"
        end
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
      chain = ActionChain.new(session: self)
      with chain yield chain
      chain
    end

    def perform_actions(debug_mouse_move = false, &block)
      chain = ActionChain.new(session: self)
      with chain yield chain
      chain.perform(debug_mouse_move)
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
        pp new_params
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
        raise "Invalid command for #{service.browser}. Command is valid for #{browser} only."
      end
    end


    enum Type
      Local
      Remote
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
