require "json"
require "uuid"
require "base64"
require "http/client"
require "compress/zip"

require "./extensions/*"
require "./marionette/logger"
require "./marionette/*"

# Marionette is a one-size-fits-all approach to WebDriver adapters. It works with most all
# web driver implementations, including:
#
# - Chrome
# - Chromium
# - Firefox
# - Safari
# - Edge
# - Internet Explorer
# - Opera
# - PhantomJS
# - Webkit GTK
# - WPE Webkit
# - Android
#
# See the README for information on getting started.
module Marionette
  extend DriverOptions
end

options = Marionette.chrome_options(experimental_options: { "excludeSwitches" => ["enable-automation"] })
session = Marionette::WebDriver.create_session(:chrome, capabilities: options)

# Navigate to crystal-lang.org
session.navigate("https://crystal-lang.org")

# Start an action chain and perform it
session.perform_actions do
  # Click the "INSTALL" link
  click ".main-actions a:nth-child(1)"
end

sleep 5
session.close
