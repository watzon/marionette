module Marionette
  module DriverOptions
    extend self

    def chrome_options(args = [] of String,
                       extensions = [] of String | IO,
                       binary = nil,
                       debugger_address = nil,
                       page_load_strategy : PageLoadStrategy? = nil,
                       experimental_options = {} of String => String,
                       logging_prefs = {} of String => String,
                       capabilities = {} of String => String)
      caps = capabilities
      opts = experimental_options

      opts = opts.merge({"args" => args}) unless args.empty?
      opts = opts.merge({"pageLoadStrategy" => page_load_strategy}) if page_load_strategy
      opts = opts.merge({"binary" => binary}) if binary
      opts = opts.merge({"debuggerAddress" => debugger_address}) if debugger_address

      loaded_extensions = [] of String
      extensions.each do |ext|
        case ext
        in IO
          loaded_extensions << Base64.encode(ext.rewind.gets_to_end)
        in String
          expanded = File.expand_path(ext)
          if File.exists?(ext)
            loaded_extensions << Base64.encode(File.read(expanded))
          end
        end
      end

      opts = opts.merge({"extensions" => loaded_extensions}) unless loaded_extensions.empty?

      caps = caps.merge({"goog:loggingPrefs" => logging_prefs}) unless logging_prefs.empty?
      caps.merge({"goog:chromeOptions" => opts})
    end

    def firefox_options(args = [] of String,
                        binary = nil,
                        page_load_strategy : PageLoadStrategy? = nil,
                        log_level = nil)
      opts = {} of String => JSON::Any

      opts = opts.merge({"args" => args}) unless args.empty?
      opts = opts.merge({"pageLoadStrategy" => page_load_strategy.to_s.downcase}) if page_load_strategy
      opts = opts.merge({"binary" => binary}) if binary
      opts = opts.merge({"log" => {"level" => log_level}}) if log_level

      {"moz:firefoxOptions" => opts}
    end

    def edge_options(args = [] of String,
                     page_load_strategy : PageLoadStrategy? = nil,
                     is_legacy = false,
                     browser_name = nil)
      opts = {} of String => JSON::Any

      opts = opts.merge({"args" => args}) unless args.empty?
      if is_legacy
        opts = opts.merge({"pageLoadStrategy" => page_load_strategy.to_s.downcase}) if page_load_strategy
      else
        opts = opts.merge({"browserName" => browser_name}) if browser_name
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

      opts = opts.merge({"id.browserCommandLineSwitches" => args.join(' ')}) unless args.empty?
      opts = opts.merge({"browserAttachTimeout" => browser_attach_timeout}) if browser_attach_timeout
      opts = opts.merge({"elementScrollBehavior" => element_scroll_behavior}) if element_scroll_behavior
      opts = opts.merge({"ie.ensureCleanSession" => ensure_clean_session}) if ensure_clean_session
      opts = opts.merge({"ie.fileUploadDialogTimeout" => file_upload_dialog_timeout}) if file_upload_dialog_timeout
      opts = opts.merge({"ie.forceCreateProcessApi" => force_create_process_api}) if force_create_process_api
      opts = opts.merge({"ie.forceShellWindowsApi" => force_shell_windows_api}) if force_shell_windows_api
      opts = opts.merge({"ie.enableFullPageScreenshot" => full_page_screenshot}) if full_page_screenshot
      opts = opts.merge({"ignoreProtectedModeSettings" => ignore_protected_mode_settings}) if ignore_protected_mode_settings
      opts = opts.merge({"ignoreZoomSetting" => ignore_zoom_level}) if ignore_zoom_level
      opts = opts.merge({"initialBrowserUrl" => initial_browser_url}) if initial_browser_url
      opts = opts.merge({"nativeEvents" => native_events}) if native_events
      opts = opts.merge({"enablePersistentHover" => persistent_hover}) if persistent_hover
      opts = opts.merge({"requireWindowFocus" => require_window_focus}) if require_window_focus
      opts = opts.merge({"ie.usePerProcessProxy" => use_per_process_proxy}) if use_per_process_proxy
      opts = opts.merge({"ie.validateCookieDocumentType" => validate_cookie_document_type}) if validate_cookie_document_type

      {"se:ieOptions" => opts}
    end

    def webkit_gtk_options(args = [] of String,
                           binary = nil,
                           overlay_scrollbars = nil)
      opts = {} of String => JSON::Any

      opts = opts.merge({"args" => args}) unless args.empty?
      opts = opts.merge({"binary" => binary}) if binary
      opts = opts.merge({"useOverlayScrollbars" => overlay_scrollbars}) if overlay_scrollbars

      {"webkitgtk:browserOptions" => opts}
    end

    def wpe_webkit_options(args = [] of String,
                           binary = nil)
      opts = {} of String => JSON::Any

      opts = opts.merge({"args" => args}) unless args.empty?
      opts = opts.merge({"binary" => binary}) if binary

      {"webkitgtk:browserOptions" => opts}
    end

    def opera_options(args = [] of String,
                      page_load_strategy : PageLoadStrategy? = nil,
                      android_package_name = nil,
                      android_device_socket = nil,
                      android_command_line_file = nil)
      opts = {} of String => JSON::Any

      opts = opts.merge({"args" => args}) unless args.empty?
      opts = opts.merge({"pageLoadStrategy" => page_load_strategy.to_s.downcase}) if page_load_strategy
      opts = opts.merge({"androidPackage" => android_package_name}) if android_package_name
      opts = opts.merge({"androidDeviceSocket" => android_device_socket}) if android_device_socket
      opts = opts.merge({"androidCommandLineFile" => android_command_line_file}) if android_command_line_file

      {"operaOptions" => opts}
    end
  end
end
