require "cute"
require "tempfile"

module PuppetMaster

  CHROME_PROFILE_PATH = File.join( Tempfile.dirname, "puppeteer_dev_profile-" )

  DEFAULT_ARGS = [
    "--disable-background-networking",
    "--disable-background-timer-throttling",
    "--disable-client-side-phishing-detection",
    "--disable-default-apps",
    "--disable-extensions",
    "--disable-hang-monitor",
    "--disable-popup-blocking",
    "--disable-prompt-on-repost",
    "--disable-sync",
    "--disable-translate",
    "--metrics-recording-only",
    "--no-first-run",
    "--remote-debugging-port=0",
    "--safebrowsing-disable-auto-update"
  ]

  AUTOMATION_ARGS = [
    "--enable-automation",
    "--password-store=basic",
    "--use-mock-keychain",
  ]

  class Launcher

    def self.launch(
      args = [] of String,          # Extra arguments to pass to the headless chrome
      ignore_defaults = false,      # Ignore the DEFAULT_ARGS
      user_data_dir = nil,          # Set the user data directory
      devtools = false,             # Auto open devtools
      headless = true,              # Run in a headless state
      executable = nil,             # Set the chrome executalble path
      env : Process::Env = nil,     # Environment variables
      slowmo = false,               # Add a connection delay
    )

      chrome_args = ignore_defaults ? [] of String : DEFAULT_ARGS

      if !headless && !ignore_defaults
        chrome_args.concat(AUTOMATION_ARGS)
      end

      if args.includes?("--user-data-dir")
        begin
          Dir.mkdir(CHROME_PROFILE_PATH) unless user_data_dir
          chrome_args.push("--user-data-dir=#{ user_data_dir || CHROME_PROFILE_PATH }")
        rescue exception
          puts "Failed to set user data directory: #{exception}"
        end
      end

      if devtools
        chrome_args.push("--auto-open-devtools-for-tabs")
        headless = false
      end

      if headless
        chrome_args.push(
          "--headless",
          "--disable-gpu",
          "--hide-scrollbars",
          "--mute-audio"
        )
      end

      if !executable
        downloader = Downloader.create_default()
        revision_info = downloader.revision_info(Downloader.current_platform, Downloader.default_revision)
        if !revision_info["downloaded"]
          raise "Chromium revision is not downloaded"
        end
        executable = revision_info["executable_path"]
      end

      chrome_args.concat(args)
      chrome_channel = Channel(Process).new

      spawn do
        Process.run(executable.as(String), chrome_args, env) do |status|
          chrome_channel.send(status)
        end
      end

      Fiber.yield
      proc = chrome_channel.receive
      return proc
    end

  end
end


# PuppetMaster::Launcher.launch(executable: "chromium-browser", devtools: true)
