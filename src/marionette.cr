require "json"
require "uuid"
require "base64"
require "http/client"
require "compress/zip"

require "./marionette/logger"
require "./marionette/*"

# TODO: Write documentation for `Marionette`
module Marionette
  extend self

  enum PageLoadStrategy
    None
    Normal
    Eager
  end

  def chrome_options(args = [] of String,
                     extensions = [] of String,
                     binary = nil,
                     debugger_address = nil,
                     page_load_strategy : PageLoadStrategy? = nil,
                     experimental_options = {} of String => String)
    opts = experimental_options.transform_values { |o| JSON.parse(o.to_json) }
    opts["args"] = JSON.parse(args.to_json)
    opts["pageLoadStrategy"] = JSON::Any.new(page_load_strategy.to_s.downcase) if page_load_strategy
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
end
