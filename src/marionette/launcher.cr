require "./utils"

module Marionette
  class Launcher
    include Logger

    DEFAULT_ARGS = ["--safe-mode", "-marionette", "-foreground", "-no-remote"]
    firefox_PROFILE_PATH = File.join(Dir.tempdir, "marionette_dev_profile-")

    # Array of handlers to call on browser exit
    getter exit_handlers : Array(Proc(Void))

    # Proxy used for viewing and modifying request info
    getter proxy : Proxy?

    # Creates a new `Launcher` instance in the specified `project_root`.
    # Optionally a preferred revision can be included, which will be
    # used if no other revision information is set.
    def initialize
      @exit_handlers = [] of Proc(Void)
    end

    # Launch a `Broswer` instance with the specified options. Configuration
    # options include:
    #
    # - **address** - The address that Firefox is listening on. (default: 127.0.0.1)
    # - **port** - The port that Firefox is listening on. (default: 2828)
    # - **executable** - The executable to launch. If `nil` an executable will be searched for. If `false` no executable will be launched.
    # - **args** - Arguments to pass to the Firefox process (only if **executable** is not false)
    # - **profile** - User profile path to launch with (only if **executable** is not false)
    # - **headless** - Launch browser in headless mode (default: true) (only if **executable** is not false)
    # - **stdout** - `IO` to use for STDOUT (only if **executable** is not false)
    # - **stderr** - `IO` to use for STDERR (only if **executable** is not false)
    # - **accept_insecure_certs** - Open all connections, even if the cert is invalid
    # - **env** - Environment to pass to `Process` (only if **executable** is not false)
    # - **default_viewport** - Default size of the browser window (default: {width: 800, height: 600})
    # - **timeout** - Universal timeout (default: 60000)
    # - **proxy** - NamedTuple with `address` and `port` for proxy.
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
      accept_insecure_certs = false,
      env = nil,
      default_viewport = {
        width:  800,
        height: 600,
      },
      timeout = 30000,
      proxy = {
        address: "127.0.0.1",
        port: 6868
      }
    )

      executable = resolve_executable_path if executable.nil?
      @proxy = Proxy.launch(proxy[:address], proxy[:port])

      proxy_config = {
        proxyType: "manual",
        httpProxy: "#{proxy[:address]}:#{proxy[:port]}",
        sslProxy: "#{proxy[:address]}:#{proxy[:port]}"
      }

      capabilities = {
        acceptInsecureCerts: accept_insecure_certs,
        proxyConfiguration: proxy_config,
        timeouts: {
          implicit: timeout,
          pageLoad: timeout,
          script: timeout
        }
      }

      if executable
        debug("Launching browser")

        args.concat(DEFAULT_ARGS)
        args << "--headless" if headless
        args << "--jsdebugger" if console
        args << "--profile #{profile}" if profile
        args << "--window-size {width},{height}" % default_viewport

        stdout ||= Process::ORIGINAL_STDOUT
        stderr ||= Process::ORIGINAL_STDERR
        Process.new(executable.to_s, args, env, output: stdout, error: stderr)
      end

      browser = Browser.new(address, port, @proxy.not_nil!, timeout)
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
