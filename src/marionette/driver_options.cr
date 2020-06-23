module Marionette
  enum PageLoadStrategy
    None
    Normal
    Eager

    def to_s(io)
      io << super.downcase
    end
  end

  enum ElementScrollBehavior
    Top
    Bottom

    def to_s(io)
      io << super.downcase
    end
  end

  module DriverOptions
    extend self

    def chrome_options(args = [] of String,
                       extensions = [] of String,
                       binary = nil,
                       debugger_address = nil,
                       page_load_strategy : PageLoadStrategy? = nil,
                       experimental_options = {} of String => String)
      opts = experimental_options.transform_values { |o| JSON.parse(o.to_json) }
      opts["args"] = JSON.parse(args.to_json)
      opts["pageLoadStrategy"] = JSON::Any.new(page_load_strategy.to_s) if page_load_strategy
      opts["binary"] = JSON::Any.new(binary) if binary
      opts["debuggerAddress"] = JSON::Any.new(debugger_address) if debugger_address

      loaded_extensions = [] of String
      extensions.each do |ext|
        expanded = File.expand_path(ext)
        if File.exists?(ext)
          loaded_extensions << Base64.encode(File.read(expanded))
        end
      end

      opts["extensions"] = JSON.parse(loaded_extensions.to_json) unless loaded_extensions.empty?
      {"goog:chromeOptions" => opts}
    end

    def firefox_options(args = [] of String,
                        binary = nil,
                        page_load_strategy : PageLoadStrategy? = nil,
                        log_level = nil)
      opts = {} of String => JSON::Any
      opts["args"] = JSON.parse(args.to_json)
      opts["pageLoadStrategy"] = JSON::Any.new(page_load_strategy.to_s.downcase) if page_load_strategy
      opts["binary"] = JSON::Any.new(binary) if binary
      opts["log"] = JSON.parse({"level" => log_level}) if log_level
      {"moz:firefoxOptions" => opts}
    end

    def edge_options(args = [] of String,
                     page_load_strategy : PageLoadStrategy? = nil,
                     is_legacy = false,
                     browser_name = nil)
      opts = {} of String => JSON::Any
      opts["args"] = JSON.parse(args.to_json)
      if is_legacy
        opts["pageLoadStrategy"] = JSON::Any.new(page_load_strategy.to_s.downcase) if page_load_strategy
      else
        opts["browserName"] = JSON::Any.new(browser_name)
      end
      {"ms:edgeOptions" => opts}
    end

    def ie_options(args = [] of String,
                   browser_attach_timeout = nil,
                   element_scroll_behavior : ElementScrollBehavior? = nil,
                   ensure_clean_session = nil,
                   file_upload_dialog_timeout = nil,
                   force_create_process_api = nil,
                   force_shell_windows_api = nil,
                   full_page_screenshot = nil,
                   ignore_protected_mode_settings = nil,
                   ignore_zoom_level = nil,
                   initial_browser_url = nil,
                   native_events = nil,
                   persistent_hover = nil,
                   require_window_focus = nil,
                   use_per_process_proxy = nil,
                   validate_cookie_document_type = nil,
                   additional_options = {} of String => String)
      opts = {} of String => JSON::Any
      opts["id.browserCommandLineSwitches"] = JSON::Any.new(args.join(' '))
      opts["browserAttachTimeout"] = JSON::Any.new(browser_attach_timeout) if browser_attach_timeout
      opts["elementScrollBehavior"] = JSON::Any.new(element_scroll_behavior) if element_scroll_behavior
      opts["ie.ensureCleanSession"] = JSON::Any.new(ensure_clean_session) if ensure_clean_session
      opts["ie.fileUploadDialogTimeout"] = JSON::Any.new(file_upload_dialog_timeout) if file_upload_dialog_timeout
      opts["ie.forceCreateProcessApi"] = JSON::Any.new(force_create_process_api) if force_create_process_api
      opts["ie.forceShellWindowsApi"] = JSON::Any.new(force_shell_windows_api) if force_shell_windows_api
      opts["ie.enableFullPageScreenshot"] = JSON::Any.new(full_page_screenshot) if full_page_screenshot
      opts["ignoreProtectedModeSettings"] = JSON::Any.new(ignore_protected_mode_settings) if ignore_protected_mode_settings
      opts["ignoreZoomSetting"] = JSON::Any.new(ignore_zoom_level) if ignore_zoom_level
      opts["initialBrowserUrl"] = JSON::Any.new(initial_browser_url) if initial_browser_url
      opts["nativeEvents"] = JSON::Any.new(native_events) if native_events
      opts["enablePersistentHover"] = JSON::Any.new(persistent_hover) if persistent_hover
      opts["requireWindowFocus"] = JSON::Any.new(require_window_focus) if require_window_focus
      opts["ie.usePerProcessProxy"] = JSON::Any.new(use_per_process_proxy) if use_per_process_proxy
      opts["ie.validateCookieDocumentType"] = JSON::Any.new(validate_cookie_document_type) if validate_cookie_document_type
      {"se:ieOptions" => opts}
    end

    def webkit_gtk_options(args = [] of String,
                           binary = nil,
                           overlay_scrollbars = nil)
      opts = {} of String => JSON::Any
      opts["args"] = JSON.parse(args.to_json)
      opts["binary"] = JSON::Any.new(binary) if binary
      opts["useOverlayScrollbars"] = JSON::Any.new(overlay_scrollbars) if overlay_scrollbars
      {"webkitgtk:browserOptions" => opts}
    end

    def wpe_webkit_options(args = [] of String,
                           binary = nil)
      opts = {} of String => JSON::Any
      opts["args"] = JSON.parse(args.to_json)
      opts["binary"] = JSON::Any.new(binary) if binary
      {"webkitgtk:browserOptions" => opts}
    end

    def opera_options(args = [] of String,
                      page_load_strategy : PageLoadStrategy? = nil,
                      android_package_name = nil,
                      android_device_socket = nil,
                      android_command_line_file = nil)
      opts = {} of String => JSON::Any
      opts["args"] = JSON.parse(args.to_json)
      opts["pageLoadStrategy"] = JSON::Any.new(page_load_strategy.to_s.downcase) if page_load_strategy
      opts["androidPackage"] = JSON::Any.new(android_package_name) if android_package_name
      opts["androidDeviceSocket"] = JSON::Any.new(android_device_socket) if android_device_socket
      opts["androidCommandLineFile"] = JSON::Any.new(android_command_line_file) if android_command_line_file
      {"operaOptions" => opts}
    end
  end
end
