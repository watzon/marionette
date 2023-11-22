require "../src/marionette"
require "spectator"

TEST_SERVICE = Marionette::Service.new(:chrome, port: 4444, host: "localhost")

TEST_DRIVER = Marionette::WebDriver.new(
  :chrome,
  URI.parse("http://localhost:4444"),
  HTTP::Client.new("localhost")
)

TEST_SESSION = Marionette::Session.new(
  TEST_DRIVER,
  id: "TEST_SESSION_ID",
  type: :local,
  service: TEST_SERVICE,
  w3c: false,
  capabilities: TEST_DRIVER.browser.desired_capabilities
)

W3C_TEST_SESSION = Marionette::Session.new(
  W3C_TEST_DRIVER,
  id: "TEST_SESSION_ID",
  type: :local,
  service: TEST_SERVICE,
  w3c: true,
  capabilities: TEST_DRIVER.browser.desired_capabilities
)
