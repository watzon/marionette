require "http/client"

module PuppetMaster

  DOWNLOAD_URLS = {
    "linux" => "%{host}/chromium-browser-snapshots/Linux_x64/%{revision}/chrome-linux.zip",
    "darwin" => "%{host}/chromium-browser-snapshots/Mac/%{revision}/chrome-mac.zip",
    "win32" => "%{host}/chromium-browser-snapshots/Win/%{revision}/chrome-win32.zip",
    "win64" => "%{host}/chromium-browser-snapshots/Win_x64/%{revision}/chrome-win32.zip"
  }

  DEFAULT_DOWNLOAD_HOST = "http://storage.googleapis.com"

  class Downloader

    property :download_host

    def initialize(@downloads_folder : String)
      @download_host = DEFAULT_DOWNLOAD_HOST
    end

    def self.default_revision
      CHROMIUM_REVISION
    end

    def self.create_default
      downloads_folder = File.join(Dir.current, ".local-chromium")
      return Downloader.new(downloads_folder)
    end

    def self.supported_platforms
      DOWNLOAD_URLS.keys
    end

    def self.current_platform
      {% if flag?(:linux) %}
        "linux"
      {% elsif flag?(:darwin) %}
        "darwin"
      {% elsif flag?(:win32) %}
        "win32"
      {% else %}
        "win64"
      {% end %}
    end

    def can_download_revision?(platform, revision)
      url = get_download_url(platform, revision)
      res = HTTP::Client.head(url, tls: nil)
      res.status_code == 200
    end

    def download_revision(platform, revision)
      url = get_download_url(platform, revision)
      zip_path = File.join(@downloads_folder, "download-#{platform}-#{revision}.zip")
      folder_path = get_folder_path(platform, revision)

      if Dir.exists?(folder_path)
        return
      end

      if !Dir.exists?(@downloads_folder)
        Dir.mkdir(@downloads_folder)
      end

      HTTP::Client.get(url, tls: nil) do |response|
        File.write(zip_path, response.body_io)
        Zip::File.open(zip_path) do |zip|
          zip.extract_all(folder_path, 0x7777)
        end
        File.delete(zip_path)
      end
    end

    def downloaded_revisions
      if Dir.exists?(@downloads_folder)
        Dir.entries(@downloads_folder).reject! { |f| [".", ".."].includes?(f) }
      else
        [] of String
      end
    end

    def remove_revision(platform, revision)
      raise "Unknown platform '#{platform}'" unless DOWNLOAD_URLS.has_key?(platform)
      folder_path = get_folder_path(platform, revision)
      if Dir.exists?(folder_path)
        `rm -rf #{folder_path}`
      end
    end

    def revision_info(platform, revision)
      raise "Unknown platform '#{platform}'" unless DOWNLOAD_URLS.has_key?(platform)
      folder_path = get_folder_path(platform, revision)
      exe_path = case Downloader.current_platform

      when "linux"
        File.join(folder_path, "chrome-linux", "chrome")
      when "darwin"
        File.join(folder_path, "chrome-mac", "Chromium.app", "Contents", "MacOS", "Chromium")
      when "win32", "win64"
        File.join(folder_path, "chrome-win32", "chrome.exe")
      else
        raise "Unknown platform '#{platform}'"
      end

      {
        revision: revision,
        executable_path: exe_path,
        folder_path: folder_path,
        downloaded: Dir.exists?(folder_path)
      }
    end

    private def get_download_url(platform, revision)
      raise "Unknown platform '#{platform}'" unless DOWNLOAD_URLS.has_key?(platform)
      DOWNLOAD_URLS[platform] % { host: @download_host, revision: revision }
    end

    private def get_folder_path(platform, revision)
      File.join(@downloads_folder, "#{platform}-#{revision}")
    end

  end
end
