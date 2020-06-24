require "../src/marionette"
require "spectator"

TEST_SERVICE = Marionette::Service.new(:chrome, port: 4444, host: "localhost")

TEST_DRIVER = Marionette::WebDriver.new(
  :chrome,
  URI.parse("http://localhost:4444"),
  HTTP::Client.new("localhost"),
  w3c: false
)

W3C_TEST_DRIVER = Marionette::WebDriver.new(
  :chrome,
  URI.parse("http://localhost:4444"),
  HTTP::Client.new("localhost"),
  w3c: true
)

TEST_SESSION = Marionette::Session.new(TEST_DRIVER, "TEST_SESSION_ID", :local, TEST_SERVICE)

W3C_TEST_SESSION = Marionette::Session.new(W3C_TEST_DRIVER, "TEST_SESSION_ID", :local, TEST_SERVICE)

Spectator.configure do |config|
  config.randomize
  config.profile
end
