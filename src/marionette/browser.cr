require "base64"

module Marionette
  class Browser
    enum BrowserContext
      Chrome
      Content
    end

    enum ScreenshotFormat
      Base64
      Hash
      Binary
    end

    getter process : Process
    getter transport : Transport

    def initialize(@process, @address : String, @port : Int32, @timeout = 60000)
      @transport = Transport.new(@timeout)
      @transport.connect(@address, @port)
    end

    # Create a new browser session
    def new_session(capabilities)
      @transport.request("WebDriver:NewSession", capabilities)
    end

    # Navigate to the specified `url`
    def goto(url)
      @transport.request("WebDriver:Navigate", {url: url})
      nil
    end

    # Get the title of the current page
    def title
      response = @transport.request("WebDriver:GetTitle")
      response["value"].as_s
    end

    # Get the current url
    def url
      response = @transport.request("WebDriver:GetCurrentURL")
      response["value"].as_s
    end

    # Refresh the page
    def refresh
      @transport.request("WebDriver:Refresh")
      nil
    end

    # Go back
    def back
      @transport.request("WebDriver:Back")
      nil
    end

    # Go forward
    def forward
      @transport.request("WebDriver:Forward")
      nil
    end

    # Sets the context of subsequent commands to be either
    # chrome or content.
    def set_context(context : BrowserContext)
      @transport.request("Marionette:SetContext", {value: context.to_s.downcase})
    end

    # Gets the context of the server
    def context
      @transport.request("Marionette:GetContext")
    end

    # Returns the current window ID
    def current_window_handle
      response = @transport.request("WebDriver:GetWindowHandle")
      response["value"].as_s
    end

    def current_chrome_window_handle
      @transport.request("WebDriver:GetCurrentChromeWindowHandle")
    end

    # Return array of window IDs currently opened
    def window_handles
      response = @transport.request("WebDriver:GetWindowHandles")
      response["value"].as_a.map(&.as_s)
    end

    # Switch to a specific window
    def switch_to_window(name)
      @transport.request("WebDriver:SwitchToWindow", {name: name})
      nil
    end

    # Returns the current window position and size
    def window_rect
      response = @transport.request("WebDriver:GetWindowRect")
      response.value
    end

    # Sets the size of the current window
    def set_window_rect(rect : WindowRect)
      @transport.request("WebDriver:SetWindowRect", {x: rect.x, y: rect.y, width: rect.width.floor, height: rect.height.floor})
      nil
    end

    # Maximizes the window
    def maximize_window
      @transport.request("WebDriver:MaximizeWindow")
      nil
    end

    # Minimizes the window
    def maximize_window
      @transport.request("WebDriver:MinimizeWindow")
      nil
    end

    # Makes the window full screen
    def fullscreen
      @transport.request("WebDriver:FullscreenWindow")
      nil
    end

    # Closes the current window
    def close_window
      @transport.request("WebDriver:CloseWindow")
      nil
    end

    # Get the screen orientation of the current browser.
    def orientation
      response = @transport.request("Marionette:GetScreenOrientation")
      response["value"].as_s
    end

    # Set the orientation
    def orientation=(orientation)
      @transport.request("Marionette:SetScreenOrientation", {orientation: orientation})
      nil
    end

    # Get the active frame
    def active_frame
      response = @transport.request("WebDriver:GetActiveFrame")
      response["value"]
    end

    # Switch to frame by id or name
    def switch_to_frame(by, value)
      frame = find_element(by, value)
      @transport.request("WebDriver:SwitchToFrame", {element: frame.id, focus: true})
      nil
    end
    
    # Switch to the parent frame
    def switch_to_parent_frame
      @transport.request("WebDriver:SwitchToParentFrame")
      nil
    end

    # Get all cookies
    def cookies
      @transport.request("WebDriver:GetCookies")
    end

    # Get a specific cookie by name
    def cookie(name)
      @transport.request("WebDriver:GetCookies", {name: name})
    end

    # Check if element is enabled
    def element_enabled?(id)
      response = @transport.request("WebDriver:IsElementEnabled", {id: id})
      response["value"].as_b
    end

    # Check if the element is selected
    def element_selected?(id)
      response = @transport.request("WebDriver:IsElementSelected", {id: id})
      response["value"].as_b
    end

    # Check if the element is displayed
    def element_selected?(id)
      response = @transport.request("WebDriver:IsElementDisplayed", {id: id})
      response["value"].as_b
    end

    # Gets the tag name of an element
    def element_tag_name(id)
      response = @transport.request("WebDriver:GetElementTagName", {id: id})
      response["value"].as_s
    end

    # Gets the text for an element
    def element_text(id)
      response = @transport.request("WebDriver:GetElementText", {id: id})
      response["value"].as_s
    end

    # Get an attribute for an element
    def element_attribute(id, name)
      response = @transport.request("WebDriver:GetElementAttribute", {id: id, name: name})
      response["value"].as_s
    end

    # Get a css property for an element
    def element_css_property(id, property)
      response = @transport.request("WebDriver:GetElementCSSValue", {id: id, propertyName: property})
      response["value"].as_s
    end

    # Get an element's rect
    def element_rect(id)
      response = @transport.request("WebDriver:GetElementRect", {id: id})
      response["value"]
    end

    # Simulate a click on a particular element
    def click_element(id)
      response = @transport.request("WebDriver:ElementClick", {id: id})
      response["value"]
    end

    # Sends keys to an element
    def send_keys_to_element(id, keys)
      response = @transport.request("WebDriver:ElementSendKeys", {id: id, keys: keys})
      response["value"]
    end

    # Clears a clearable element
    def clear_element(id)
      response = @transport.request("WebDriver:ElementClear", {id: id})
      response["value"]
    end

    # Find elements using the indicated search strategy
    def find_elements(by, value)
      find_elements(by, value, nil)
    end

    # Find elements using the indicated search strategy and
    # starting with a particular node.
    def find_elements(by, value, start_node)
      if start_node.nil? || start_node.empty?
        params = {using: by.to_s.downcase, value: value}
      else
        params = {using: by.to_s.downcase, value: value, element: start_node} 
      end

      response = @transport.request("WebDriver:FindElements", params)
      response # TODO: Make into a array of WebElement
    end

    # Find a single element using the indicated search strategy.
    def find_element(by, value)
      find_element(by, value, nil)
    end

    # Find a single element using the indicated search strategy and
    # starting with a particular node.
    def find_elements(by, value, start_node)
      if start_node.nil? || start_node.empty?
        params = {using: by.to_s.downcase, value: value}
      else
        params = {using: by.to_s.downcase, value: value, element: start_node} 
      end

      response = @transport.request("WebDriver:FindElement", params)
      response["value"]
    end

    # Takes a screenshot of an element or the current frame.
    # Optionally also allows you to highlight specific elements.
    # Format can be `:hash`, :binary, or `:base64` (default).
    def take_screenshot(
      element = nil,
      highlights = nil,
      full = true,
      scroll = true,
      format = ScreenshotFormat::Binary
    )
      params = {
        id: element,
        highlights: highlights,
        full: full,
        scroll: scroll,
        hash: format == :hash
      }

      response = @transport.request("WebDriver:TakeScreenshot", params)
      data = response["value"].as_s

      case format
      when ScreenshotFormat::Binary
        Base64.decode_string(data)
      else
        data
      end
    end

    # Captures and saves a screenshot. See `#take_screenshot`.
    def save_screenshot(file, **options)
      options = options.merge(format: ScreenshotFormat::Binary)
      data = take_screenshot(**options)
      File.write(file, data)
    end

    # Get the source for the current page.
    def page_source
      @transport.request("WebDriver:GetPageSource")
    end

    # Execute JS script. If `new_sandbox` is true (default) the global
    # variables from the last executed script will be preserved. The
    # result of executing the script is returned.
    def execute_script(script, args = nil, timeout = @timeout, new_sandbox = true)
      params = {
        scriptTimeout: timeout,
        script: script,
        args: args || [] of String,
        newSandbox: sandbox
      }

      response = @transport.request("WebDriver:ExecuteScript", params)
      response["value"].as_s?
    end

    # Execute JS script asynchronously. See `#execute_script`.
    def execute_script_async(script, args = nil, timeout = @timeout, new_sandbox = true)
      params = {
        scriptTimeout: timeout,
        script: script,
        args: args || [] of String,
        newSandbox: sandbox
      }

      response = @transport.request("WebDriver:ExecuteScriptAsync", params)
      response["value"].as_s?
    end

    # Dismisses the dialog like clicking no/cancel.
    def dismiss_dialog
      @transport.request("WebDriver:DismissAlert")
      nil
    end

    # Accepts a dialog lick clicking ok/yes
    def accept_dialog
      @transport.request("WebDriver:AcceptAlert")
      nil
    end

    # Gets the text from a dialog
    def text_from_dialog
      response = @transport.request("WebDriver:GetAlertText")
      response["value"].as_s
    end

    # Sends text to a dialog
    def send_keys_to_dialog(keys)
      @transport.request("WebDriver:SendAlertText", {text: keys})
      nil
    end

    # Closes the browser
    def quit
      @transport.request("Marionette:Quit", {flags: ["eForceQuit"]})
    end

    record WindowRect, x : Int32, y : Int32, width : Int32, height : Int32
    record WebElement, id : String
  end
end
