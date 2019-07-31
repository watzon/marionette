require "http/client"

module Marionette
  class Downloader
    include Logger

    DOWNLOAD_URLS = {
      "linux" => "%{host}/chromium-browser-snapshots/Linux_x64/%{revision}/chrome-linux.zip",
      "mac"   => "%{host}/chromium-browser-snapshots/Mac/%{revision}/chrome-mac.zip",
      "win32" => "%{host}/chromium-browser-snapshots/Win/%{revision}/chrome-win32.zip",
      "win64" => "%{host}/chromium-browser-snapshots/Win_x64/%{revision}/chrome-win32.zip",
    }

    DEFAULT_DOWNLOAD_HOST = "http://storage.googleapis.com"

    # The host from which to download the headless
    # Chromium instance.
    property :download_host

    # Returns the downloads folder for this downloader.
    getter download_dir : String

    # Create a new downloader instance with the specified
    # `download_dir` and `download_host`
    def initialize(
      @download_dir = Downloader.default_download_dir,
      @download_host = DEFAULT_DOWNLOAD_HOST
    )
    end

    # The default download directory. Defaults to
    # `{pwd}/.headless_chrome`.
    def self.default_download_dir
      File.join(FileUtils.pwd, ".headless_chrome")
    end

    # Gets the default chromium revision to download.
    # See `CHROMIUM_REVISION`
    def self.default_revision
      # Located in version.cr
      CHROMIUM_REVISION
    end

    # Gets a list of platforms supported by Marionette.
    def self.supported_platforms
      DOWNLOAD_URLS.keys
    end

    # Returns the platform this was built on.
    def self.current_platform
      {% if flag?(:linux) %}
        "linux"
      {% elsif flag?(:darwin) %}
        "mac"
      {% elsif flag?(:win32) %}
        "win32"
      {% else %}
        "win64"
      {% end %}
    end

    # Determine if a download exists for the given
    # `platform` and `revision`
    def can_download?(platform, revision)
      url = get_download_url(platform, revision)
      res = HTTP::Client.head(url, tls: nil)
      res.status_code == 200
    end

    # Executes a download for the given `platform` and
    # `revision`. If they are nil the defaults will
    # be downloaded.
    def download(
      platform = Downloader.current_platform,
      revision = Downloader.default_revision
    )
      url = get_download_url(platform, revision)
      zip_path = File.join(@download_dir, "download-#{platform}-#{revision}.zip")
      folder_path = get_folder_path(platform, revision)

      debug("Starting download of headless chrome for #{platform}, revision #{revision}")

      if Dir.exists?(folder_path)
        debug("Directory at #{folder_path} already exists. Skipping download.")
        return
      end

      if !Dir.exists?(@download_dir)
        debug("Making directory #{@download_dir}")
        Dir.mkdir(@download_dir)
      end

      debug("Downloading headless chrome")
      HTTP::Client.get(url, tls: nil) do |response|
        File.write(zip_path, response.body_io)

        debug("Extracting chrome to #{folder_path}")
        Zip::File.open(zip_path) do |zip|
          zip.extract_all(folder_path, 0x7777)
        end

        debug("Deleting zip file")
        File.delete(zip_path)
      end
    end

    # List downloaded revisions
    def downloaded_revisions
      if Dir.exists?(@download_dir)
        Dir.entries(@download_dir).reject! { |f| [".", ".."].includes?(f) }
      else
        [] of String
      end
    end

    # Remove a specific revision
    def remove_revision(platform, revision)
      raise "Unknown platform '#{platform}'" unless DOWNLOAD_URLS.has_key?(platform)
      folder_path = get_folder_path(platform, revision)
      if Dir.exists?(folder_path)
        `rm -rf #{folder_path}`
      end
    end

    # Gets the information for a specific revision
    def revision_info(revision, platform = Downloader.current_platform)
      raise "Unknown platform '#{platform}'" unless DOWNLOAD_URLS.has_key?(platform)
      folder_path = get_folder_path(platform, revision)

      exe_path = case platform.to_s
                 when "linux"
                   File.join(folder_path, "chrome-linux", "chrome")
                 when "mac"
                   File.join(folder_path, "chrome-mac", "Chromium.app", "Contents", "MacOS", "Chromium")
                 when "win32", "win64"
                   File.join(folder_path, "chrome-win32", "chrome.exe")
                 else
                   raise "Unknown platform '#{platform}'"
                 end

      {
        revision:        revision,
        executable_path: exe_path,
        folder_path:     folder_path,
        downloaded:      Dir.exists?(folder_path),
      }
    end

    private def get_download_url(platform, revision)
      raise "Unknown platform '#{platform}'" unless DOWNLOAD_URLS.has_key?(platform)
      DOWNLOAD_URLS[platform] % {host: @download_host, revision: revision}
    end

    private def get_folder_path(platform, revision)
      File.join(@download_dir, "#{platform}-#{revision}")
    end
  end
end
