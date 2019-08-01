require "./core_mods/*"
require "./marionette/logger"
require "./marionette/error"
require "./marionette/*"

# TODO: Write documentation for `Marionette`
module Marionette
  extend self

  # See `Launcher#launch`
  def launch(**options)
    Launcher.new.launch(**options)
  end

  def launch(**options, &block)
    browser = Launcher.new.launch(**options)
    with browser yield browser
    browser.quit unless options[:executable]? == false
  end
end

Marionette.launch(executable: nil) do
  goto("https://google.com")
  input = find_element(:xpath, "//input[@name='q']")
  input.try &.send_keys("yay this is cool!")
  input.try &.save_screenshot("input.jpg")
end
