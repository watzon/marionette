require "json"

module Marionette
  # Represents an HTML DOM element
  struct HTMLElement
    include JSON::Serializable

    getter id : String
    getter browser : Browser

    def initialize(@browser : Browser, @id : String)
    end

    # Returns an `HTMLElement` instance that matches the specified
    # method and target, relative to the current element.
    def find_element(by, target)
      @browser.find_element(by, target, @id)
    end

    # Returns an array of all `HTMLElement`s that matches the specified
    # method and target, relative to the current element.
    def find_elements(by, target)
      @browser.find_elements(by, target, @id)
    end

    # Returns the value of the requested attribute
    def attribute(name)
      params = {id: @id, name: name}
      response = @browser.transport.request("WebDriver:GetElementAttribute", params)
      response["value"].as_s?
    end

    # Returns the requested property
    def property(name)
      params = {id: @id, name: name}
      response = @browser.transport.request("WebDriver:GetElementProperty", params)
      response["value"].as_s?
    end

    # Simulate a click on the element
    def click
      @browser.transport.request("WebDriver:ElementClick", {id: @id})
    end

    # Simulate a tap event
    def tap(x = nil, y = nil)
      body = {id: @id, x: x, y: y}
      @browser.transport.request("WebDriver:SingleTap", body)
    end

    # Returns the visible text of the element and its children
    def text
      response = @browser.transport.request("WebDriver:GetElementText", {id: @id})
      response["value"].as_s
    end

    # Sends synthesized keypresses to the element
    def send_keys(*keys)
      @browser.transport.request("WebDriver:ElementSendKeys", {id: @id, text: keys.join})
    end

    # Clears the input of the element
    def clear
      @browser.transport.request("WebDriver:ElementClear", {id: @id})
    end

    # Returns true if the element is selected
    def selected?
      response = @browser.transport.request("WebDriver:IsElementSelected", {id: @id})
      response["value"].as_bool
    end

    # Returns true if the element is enabled
    def enabled?
      response = @browser.transport.request("WebDriver:IsElementEnabled", {id: @id})
      response["value"].as_bool
    end

    def displayed?
      response = @browser.transport.request("WebDriver:IsElementDisplayed", {id: @id})
      response["value"].as_bool
    end

    # Returns the element's bounding rectangle
    def rect
      response = @browser.transport.request("WebDriver:IsElementSelected", {id: @id})
      response
    end

    # Get the value of the specified CSS property
    def css_property(property)
      props = {id: @id, propertyName: property}
      response = @browser.transport.request("WebDriver:GetElementCSSValue", props)
      response["value"].as_s
    end

    # Take a screenshot of this element.
    # See `Browser#take_screenshot`
    def take_screenshot(**options)
      options = options.merge(element: @id)
      @browser.take_screenshot(**options)
    end

    # Save a screenshot of this element to a file.
    # See `Browser#save_screenshot`
    def save_screenshot(file, **options)
      options = options.merge(element: @id)
      @browser.save_screenshot(file, **options)
    end
    
    # The select method is used to find an option element under the current node.
    # As the value is can be send either a innerText or a value of "value" attribute of option node.
    def select(value)
      opt = find_element(Browser::LocatorStrategy::XPATH, ".//option[contains(text(), \"#{value}\")] | .//option[@value = \"#{value}\"]")

      if !opt.nil?
        opt.click unless opt.selected?
      end

      raise "Cannot locate option with value: #{value.inspect}"
    end
  end
end
