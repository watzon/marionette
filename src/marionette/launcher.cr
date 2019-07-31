require "./utils"

module Marionette
  class Launcher
    include Logger

    DEFAULT_ARGS = ["--safe-mode", "-marionette", "-foreground", "-no-remote"]
    firefox_PROFILE_PATH = File.join(Dir.tempdir, "marionette_dev_profile-")

    # Array of handlers to call on browser exit
    getter exit_handlers : Array(Proc(Void))

    # Creates a new `Launcher` instance in the specified `project_root`.
    # Optionally a preferred revision can be included, which will be
    # used if no other revision information is set.
    def initialize
      @exit_handlers = [] of Proc(Void)
    end

    # Launch a `Broswer` instance with the specified options. Configuration
    # options include:
    #
    # - args - extra arguments to pass to the firefox process
    # - ignore_defaults - gnore the `DEFAULT_ARGS`
    # - user_data_dir - set the user data directory
    # - devtools - auto open devtools (graphical only)
    # - headless - run in a headless state
    # - pipe - run in piped mode
    # - executable - set the firefox executable path
    # - env - set environment variables to be passed to firefox process
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
      address = "127.0.0.1",
      port = 2828,
      args = [] of String,
      profile = nil,
      console = false,
      headless = true,
      executable = nil,
      stdout = nil,
      stderr = nil,
      handle_sigint = true,
      handle_sigterm = true,
      handle_sighup = true,
      accept_insecure_certs = false,
      env = nil,
      default_viewport = {
        width:  800,
        height: 600,
      },
      timeout = 30000,
      proxy_configuration = {} of String => String
    )
      debug("Launching browser")

      executable = resolve_executable_path if executable.nil?
      capabilities = {
        acceptInsecureCerts: accept_insecure_certs,
        proxyConfiguration: proxy_configuration,
        timeouts: {
          implicit: timeout,
          pageLoad: timeout,
          script: timeout
        }
      }

      if executable
        args.concat(DEFAULT_ARGS)
        args << "--headless" if headless
        args << "--jsdebugger" if console
        args << "--profile #{profile}" if profile
        args << "--window-size {width},{height}" % default_viewport
        
        stdout ||= Process::ORIGINAL_STDOUT
        stderr ||= Process::ORIGINAL_STDERR
        Process.new(executable.to_s, args, env, output: stdout, error: stderr)
      end

      set_exit_handlers(handle_sigint, handle_sigterm, handle_sighup)

      browser = Browser.new(address, port, timeout)
      browser.new_session(capabilities)
      browser
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

        debug("Using firefox executable at #{absolute_path}")
        return absolute_path
      else
        on_path = Utils.which("firefox")

        if on_path
          debug("Using firefox executable at #{on_path}")
          return on_path
        else
          error = <<-TEXT
          Firefox executable could not be found. Please do one of the following:
            - set the executable option in Launcher#new
            - set the MARIONETTE_EXECUTABLE_PATH environment variable
            - set the MARIONETTE_REVISION environment variable to a downloaded revision
            - install Firefox using your package manager and make sure it exists on your PATH
          TEXT

          crit(error)
          raise Error::ExecutableNotFound.new(error)
        end
      end
    end

    private def set_exit_handlers(sigint, sigterm, sighup)

    end
  end
end
