require "./utils"

class Marionette
  class Launcher
    include Logger

    CHROME_PROFILE_PATH = File.join(Dir.tempdir, "marionette_dev_profile-")

    DEFAULT_ARGS = [
      "--disable-background-networking",
      "--enable-features=NetworkService,NetworkServiceInProcess",
      "--disable-background-timer-throttling",
      "--disable-backgrounding-occluded-windows",
      "--disable-breakpad",
      "--disable-client-side-phishing-detection",
      "--disable-default-apps",
      "--disable-dev-shm-usage",
      "--disable-extensions",
      # TODO: Support OOOPIF. @see https://github.com/GoogleChrome/puppeteer/issues/2548
      # BlinkGenPropertyTrees disabled due to crbug.com/937609
      "--disable-features=site-per-process,TranslateUI,BlinkGenPropertyTrees",
      "--disable-hang-monitor",
      "--disable-ipc-flooding-protection",
      "--disable-popup-blocking",
      "--disable-prompt-on-repost",
      "--disable-renderer-backgrounding",
      "--disable-sync",
      "--force-color-profile=srgb",
      "--metrics-recording-only",
      "--no-first-run",
      "--enable-automation",
      "--password-store=basic",
      "--use-mock-keychain",
    ]

    HEADLESS_ARGS = [
      "--headless",
      "--disable-gpu",
      "--hide-scrollbars",
      "--mute-audio",
    ]

    AUTOMATION_ARGS = [
      "--enable-automation",
      "--password-store=basic",
      "--use-mock-keychain",
    ]

    # The root directory of the current project
    getter project_root : String

    # Preferred chrome revision
    getter preferred_revision : Int32

    # The chrome browser process
    getter process : Process?

    # Connection instance for this Launcher
    getter connection : Connection?

    # Array of handlers to call on browser exit
    getter exit_handlers : Array(Proc(Void))

    # The arguments chrome will be launched with
    getter chrome_args : Array(String)

    # Creates a new `Launcher` instance in the specified `project_root`.
    # Optionally a preferred revision can be included, which will be
    # used if no other revision information is set.
    def initialize(@project_root, preferred_revision = nil)
      @preferred_revision = preferred_revision || Downloader.default_revision
      @exit_handlers = [] of Proc(Void)
      @chrome_args = DEFAULT_ARGS
    end

    # Launch a `Broswer` instance with the specified options. Configuration
    # options include:
    #
    # - args - extra arguments to pass to the chrome process
    # - ignore_defaults - gnore the `DEFAULT_ARGS`
    # - user_data_dir - set the user data directory
    # - devtools - auto open devtools (graphical only)
    # - headless - run in a headless state
    # - pipe - run in piped mode
    # - executable - set the chrome executable path
    # - env - set environment variables to be passed to chrome process
    # - slowmo - add a connection delay (milliseconds)
    # - std_out - set the standard out for the browser process
    # - std_error - set the standard error for the browser process
    # - handle_sigint - graceful browser exit on `SIGINT`
    # - handle_sigterm - graceful browser exit on `SIGTERM`
    # - handle_sighup - graceful browser exit on `SIGHUP`
    # - ignore_https_errors - ignore HTTPS errors and don't report them
    # - default_viewport - default viewport size (graphical only)
    # - timeout - wait timeout for the browser process
    def launch(
      args = [] of String,
      ignore_defaults = false,
      user_data_dir = nil,
      devtools = false,
      headless = true,
      pipe = false,
      executable = nil,
      env = nil,
      slowmo = 0,
      stdout = nil,
      stderr = nil,
      handle_sigint = true,
      handle_sigterm = true,
      handle_sighup = true,
      ignore_https_errors = false,
      default_viewport = {
        width:  800,
        height: 600,
      },
      timeout = 30000
    )
      debug("Launching browser")

      executable = resolve_executable_path unless executable
      @chrome_args = build_launcher_args(args, ignore_defaults, user_data_dir, devtools, headless, pipe)

      stdout = IO::Memory.new
      stderr = IO::Memory.new

      debug("Launching with args #{chrome_args.join(" ")}")
      @process = process = Process.new(executable.to_s, @chrome_args, env, output: stdout, error: stderr)

      set_exit_handlers(handle_sigint, handle_sigterm, handle_sighup)

      # TODO: Add pipe transport support
      ws_endpoint = wait_for_ws_endpoint(stderr, timeout, @preferred_revision)
      transport = WebsocketTransport.create(ws_endpoint)
      connection = Connection.new(ws_endpoint, transport, slowmo)
      browser = Browser.create(connection, [] of String, ignore_https_errors, default_viewport, process)
      browser.wait_for_target { |target| target.type == "page" }
      browser
    end

    # Force kill the chrome process
    def kill_chrome
      debug("Killing chrome process")
      if (conn = connection) && (proc = process)
        begin
          conn.send("Browser.close")
        rescue ex
          error(ex.message.to_s)
          proc.kill
        end
        @exit_handlers.each(&.call)
      else
        warning("Force killing chrome")
        @process.try &.kill
      end
    end

    # Get the path to the executable using, in order of importance:
    #
    # - `ENV["MARIONETTE_EXECUTABLE_PATH"]`
    # - `ENV["MARIONETTE_REVISION"]`
    # - `@preferred_revision`
    # - `PATH`
    def resolve_executable_path
      if executable_path = ENV["MARIONETTE_EXECUTABLE_PATH"]?
        absolute_path = File.expand_path(executable_path, __DIR__)

        unless File.executable?(absolute_path)
          raise "Tried to use MARIONETTE_EXECUTABLE_PATH env variable to launch browser but did not find any executable at: #{executable_path}"
        end

        debug("Using chrome executable at #{absolute_path}")
        return absolute_path
      elsif revision = ENV["MARIONETTE_REVISION"]?
        revision_info = Downloader.new.revision_info(revision)
        executable_path = revision_info[:executable_path]

        unless revision_info[:downloaded]
          raise "Tried to use PUPPETEER_CHROMIUM_REVISION env variable to launch browser but did not find executable at: #{executable_path}"
        end

        debug("Using chrome executable at #{executable_path}")
        return executable_path
      else
        on_path = Utils.which("chrome") || Utils.which("chromium")
        revision_info = Downloader.new.revision_info(@preferred_revision)
        executable_path = revision_info[:executable_path]

        if revision_info[:downloaded]
          debug("Using chrome executable at #{executable_path}")
          return executable_path
        elsif on_path
          debug("Using chrome executable at #{on_path}")
          return on_path
        else
          error = <<-TEXT
          Chrome executable could not be found. Please do one of the following:
            - set the executable option in Launcher#new
            - set the MARIONETTE_EXECUTABLE_PATH environment variable
            - set the MARIONETTE_REVISION environment variable to a downloaded revision
            - install Chrome or Chromium using your package manager and make sure it exists on your PATH
          TEXT

          crit(error)
          raise Error::ExecutableNotFound.new(error)
        end
      end
    end

    # Add a proc to be called after the chrome process
    # is exited.
    def on_exit(&block : Void ->)
      @exit_handlers << block
    end

    private def build_launcher_args(args, ignore_defaults, user_data_dir, devtools, headless, pipe)
      chrome_args = ignore_defaults ? [] of String : DEFAULT_ARGS

      if !headless && !ignore_defaults
        chrome_args.concat(AUTOMATION_ARGS)
      end

      unless chrome_args.any? { |arg| arg.starts_with?("--remote-debugging-") }
        chrome_args.push(pipe ? "--remote-debugging-pipe" : "--remote-debugging-port=0")
      end

      unless chrome_args.any? { |arg| arg.starts_with?("--user-data-dir") }
        begin
          user_data_dir = user_data_dir || CHROME_PROFILE_PATH
          Dir.mkdir_p(user_data_dir)
          chrome_args.push("--user-data-dir=#{user_data_dir}")
          debug("User data directory set to #{user_data_dir}")
        rescue exception
          error("Failed to set user data directory: #{exception}")
        end
      end

      if devtools
        if headless
          warning("The devtools option was true, but browser is running headless. Option will be ignored.")
        else
          chrome_args.push("--auto-open-devtools-for-tabs")
          headless = false
        end
      end

      if headless
        chrome_args.concat(HEADLESS_ARGS)
      end

      chrome_args.concat(args)
    end

    # Handle graceful browser exit in case of various signals
    private def set_exit_handlers(handle_sigint, handle_sigterm, handle_sighup)
      if handle_sigint
        Signal::INT.trap do
          kill_chrome
        end
      end

      if handle_sigterm
        Signal::TERM.trap do
          kill_chrome
        end
      end

      if handle_sighup
        Signal::HUP.trap do
          kill_chrome
        end
      end
    end

    private def wait_for_ws_endpoint(io, timeout, preferred_revision)
      started_at = Time.now
      debug("Waiting for websocket endpoint")

      sleep(1)
      loop do
        io.rewind
        lines = io.gets_to_end

        if match = lines.match(/(ws:\/\/.*)/)
          debug("Found chrome websocket endpoint: #{match[1]}")
          return match[1]
        end

        if Time.now > started_at + timeout.milliseconds
          kill_chrome
          raise "Timed out after #{timeout} ms while trying to connect to Chrome! The only Chrome revision guaranteed to work is r#{preferred_revision}"
        end
      end
    end
  end
end
