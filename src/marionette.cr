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
