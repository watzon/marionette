# Marionette

Marionette is a Crystal shard that replaces the functionality of Selenium (Firefox only for now) by communicating directly with an instance of the browser. It provides a simple, but powserful API which allows everything from navigation to screenshots to executing JavaScript.

- [Marionette](#marionette)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Launch options](#launch-options)
    - [The Browser Class](#the-browser-class)
      - [new_session(capabilities)](#newsessioncapabilities)
      - [close_session](#closesession)
      - [on_request(&block : HTTP::Server::Context ->)](#onrequestblock--httpservercontext)
      - [on_headers(&block : HTTP::Headers ->)](#onheadersblock--httpheaders)
      - [on_har_capture(&block : HAR::Entries ->)](#onharcaptureblock--harentries)
      - [har_entries](#harentries)
      - [generate_har](#generatehar)
      - [export_har(file, har = nil)](#exportharfile-har--nil)
      - [goto(url)](#gotourl)
      - [title](#title)
      - [url](#url)
      - [refresh](#refresh)
      - [back](#back)
      - [forward](#forward)
      - [set_context](#setcontext)
      - [context](#context)
      - [using_context(&block)](#usingcontextblock)
      - [current_window_handle](#currentwindowhandle)
      - [current_chrome_window_handle](#currentchromewindowhandle)
      - [window_handles](#windowhandles)
      - [switch_to_window(handle)](#switchtowindowhandle)
      - [window_rect](#windowrect)
      - [set_window_rect(rect : WindowRect)](#setwindowrectrect--windowrect)
      - [maximize_window](#maximizewindow)
      - [minimize_window](#minimizewindow)
      - [fullscreeen](#fullscreeen)
      - [close_window](#closewindow)
      - [orientation](#orientation)
      - [set_orienation](#setorienation)
      - [active_frame](#activeframe)
      - [switch_to_frame(frame : String | HTMLElement | Nil, focus: true)](#switchtoframeframe--string--htmlelement--nil-focus-true)
      - [switch_to_frame(by : LocatorStrategy, value, focus = true)](#switchtoframeby--locatorstrategy-value-focus--true)
      - [switch_to_parent_frame](#switchtoparentframe)
      - [cookies](#cookies)
      - [cookie(name)](#cookiename)
      - [element_enabled?(el)](#elementenabledel)
      - [element_selected?(el)](#elementselectedel)
      - [element_displayed?(el)](#elementdisplayedel)
      - [element_tag_name(el)](#elementtagnameel)
      - [element_text(el)](#elementtextel)
      - [element_attribute(el, name)](#elementattributeel-name)
      - [element_css_property(el, property)](#elementcsspropertyel-property)
      - [element_rect(el)](#elementrectel)
      - [click_element(el)](#clickelementel)
      - [send_keys_to_element(el, *keys)](#sendkeystoelementel-keys)
      - [clear_element(el)](#clearelementel)
      - [find_elements(by : LocatorStrategy, value, start_node = nil)](#findelementsby--locatorstrategy-value-startnode--nil)
      - [find_element(by : LocatorStrategy, value, start_node = nil)](#findelementby--locatorstrategy-value-startnode--nil)
      - [take_screenshot(**options)](#takescreenshotoptions)
        - [Options](#options)
      - [save_screenshot(file, **options)](#savescreenshotfile-options)
      - [execute_script(script, args = nil, timeout = @timeout, new_sandbox = true)](#executescriptscript-args--nil-timeout--timeout-newsandbox--true)
      - [execute_script_async(script, args = nil, timeout = @timeout, new_sandbox = true)](#executescriptasyncscript-args--nil-timeout--timeout-newsandbox--true)
      - [dismiss_dialog](#dismissdialog)
      - [accept_dialog](#acceptdialog)
      - [get_text_from_dialog](#gettextfromdialog)
      - [send_keys_to_dialog(*keys)](#sendkeystodialogkeys)
      - [quit](#quit)
      - [restart](#restart)
      - [clear_pref(pref)](#clearprefpref)
      - [pref(pref, default_branch = false, value_type = "unspecified")](#prefpref-defaultbranch--false-valuetype--%22unspecified%22)
      - [set_pref(pref, value, default_branch = false)](#setprefpref-value-defaultbranch--false)
      - [set_prefs(prefs, defualt_branch = false)](#setprefsprefs-defualtbranch--false)
      - [using_prefs(prefs, default_branch = false, &block)](#usingprefsprefs-defaultbranch--false-block)
  - [Contributing](#contributing)
  - [Contributors](#contributors)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  marionette:
    github: watzon/marionette
```

## Usage

First, of course, you need to require marionette in your project.

```crystal
require "marionette"
```

`Marionette` itself is a module which exposes two methods:

- `launch(**options)`
- `launch(**options, &block : Browser ->)`

The first `launch` method accepts [the launch options listed below](#launch-options) and returns a new `Browser` instance. The browser will not be closed at the end of the program's execution, so it's important to remember to run `Browser#quit` if the browser process was created with marionette.

The second `launch` method accepts [the same launch options](#launch-options) and a block. The newly created `Browser` instance is yielded to the block and the browser process will be closed automatically at the end of the block if the process was created with marionette.

### Launch options

`Marionette.launch` accepts all the same arguments as `Launcher#launch`. These arguments are:

- **address** - The address that Firefox is listening on. (default: 127.0.0.1)
- **port** - The port that Firefox is listening on. (default: 2828)
- **executable** - The executable to launch. If `nil` an executable will be searched for. If `false` no executable will be launched.
- **args** - Arguments to pass to the Firefox process (only if **executable** is not false)
- **profile** - User profile path to launch with (only if **executable** is not false)
- **headless** - Launch browser in headless mode (default: true) (only if **executable** is not false)
- **stdout** - `IO` to use for STDOUT (only if **executable** is not false)
- **stderr** - `IO` to use for STDERR (only if **executable** is not false)
- **accept_insecure_certs** - Open all connections, even if the cert is invalid
- **env** - Environment to pass to `Process` (only if **executable** is not false)
- **default_viewport** - Default size of the browser window (default: {width: 800, height: 600})
- **timeout** - Universal timeout (default: 60000)
- **proxy** - NamedTuple with `address` and `port` for proxy.

### The Browser Class

Most of the time while using marionette you will be dealing directly with the `Browser` class. As its name implies, the `Browser` class represents the browser instance. It includes a plethora of methods for interacting with the browser, I'll try and document them here as best as I can.

#### new_session(capabilities)

Create a new browser session with provided `capabilities` and returns the `session_id`.

```crystal
browser.new_session({"browserName": "chrome", "platformName": "linux"})
```

#### close_session

Closes the current session without shutting down the browser.

```crystal
browser.close_session
```

#### on_request(&block : HTTP::Server::Context ->)

> Note: To use this method the `extended` option must be set to true.

Passes the full `HTTP::Server::Context` to the provided block for every request made by the browser. This method can be called more than once to add multiple handlers.

```crystal
browser.on_request do |ctx|
  pp ctx.requst
  pp ctx.response
end
```

#### on_headers(&block : HTTP::Headers ->)

> Note: To use this method the `extended` option must be set to true.

Passes the headers for every request to the provided block. This method can be called more than once to add multiple handlers.

```crystal
browser.on_headers do |headers|
  pp headers
end
```

#### on_har_capture(&block : HAR::Entries ->)

> Note: To use this method the `extended` option must be set to true.

When the `extended` option is set to true automatic [HAR](https://en.wikipedia.org/wiki/.har) capturing will be enabled. `on_har_capture` sends each captured `HAR::Entries` object to the provided block.

```crystal
browser.on_har do |har|
  pp har
end
```

#### har_entries

> Note: To use this method the `extended` option must be set to true.

Lists each an every `HAR::Entries` object captured so far.

```crystal
browser.har_entries
# => [] of HAR::Entries
```

#### generate_har

> Note: To use this method the `extended` option must be set to true.

Generates a `HAR::Data` object which can be modified or converted to json using `to_json`. This represents a `.har` file.

```crystal
browser.generate_har
# => <#HAR::Data ...>
```

#### export_har(file, har = nil)

> Note: To use this method the `extended` option must be set to true.

Generates and saves a `.har` file to the specified path. You can optionally provide it with a `HAR::Data` object to be saved.

```crystal
browser.export_har("google.com.har")
```

#### goto(url)

Navigates the browser to the specified URL. If `extended` is true this will use a proxy under the hood to fetch the content from the URL and deliver it to the browser, otherwise the default WebDriver method will be used.

```crystal
browser.goto("https://www.google.com")
```

#### title

Gets the title of the current page.

```crystal
browser.goto("https://www.google.com")
browser.title
# => "Google"
```

#### url

Gets the URL of the current page.

```crystal
browser.goto("https://www.google.com")
browser.url
# => "https://www.google.com"
```

#### refresh

Refreshes the page.

```crystal
browser.refresh
```

#### back

Goes back to the previous page.

```crystal
browser.back
```

#### forward

Goes forward to the next page.

```crystal
browser.forward
```

#### set_context

Sets the context of subsequent commands to be either `:chrome` (allowing you access to the Firefox UI itself) or `:content` (allowing access to the current page).

```crystal
browser.set_context(:chrome)
browser.set_context(:content)
```

#### context

Gets the current browser context.

```crystal
browser.context
# => BrowserContext::Content
browser.set_context(:chrome)
browser.context
# => BrowserContext::Chrome
```

#### using_context(&block)

Sets the context for the provided block, then returns it to the previous context.

```crystal
using_context do
  # Do stuff
end
```

#### current_window_handle

Gets the handle for the current window, useful for switching between window instances.

```crystal
browser.current_window_handle
```

#### current_chrome_window_handle

Get the current chrome window's handle. Corresponds to a chrome window that may itself contain tabs identified by window_handles.

```crystal
browser.current_chrome_window_handle
```

#### window_handles

Returns an array of handles for currently open windows.

```crystal
browser.current_window_handles
# => ["123..."]
```

#### switch_to_window(handle)

Switches to the window with the provided handle.

```crystal
browser.switch_to_window("123...")
```

#### window_rect

Gets the current window as a `WindowRect` instance containing it's `x` and `y` positions as well as it's `width` and `height`.

```crystal
browser.window_rect
# => <#Window:Rect x: 0, y: 0, width: 800, height: 600>
```

#### set_window_rect(rect : WindowRect)

Sets the window's size and position according to the provided `WindowRect` instance.

```crystal
rect = Marionette::WindowRect.new(x: 0, y: 0, width: 800, height: 600)
browser.set_window_rect(rect)
```

#### maximize_window

Maximizes the current window.

```crystal
browser.maximize_window
```

#### minimize_window

Minimizes the current window.

```crystal
browser.minimize_window
```

#### fullscreeen

Makes the current window fullscreen.

```crystal
browser.fullscreen
```

#### close_window

Closes the current window.

```crystal
browser.close_window
```

#### orientation

Get the screen orientation of the current browser. Returns either portrait-primary, landscape-primary, portrait-secondary, or landscape-secondary.

TODO: Use an enum for this.

```crystal
browser.orientation
# => "portrait-primary"
```

#### set_orienation

Set the screen orientation to one of portrait-primary, landscape-primary, portrait-secondary, or landscape-secondary.

TODO: Use an enum for this.

```crystal
browser.set_orientation("landscape-secondary")
```

#### active_frame

Gets the current frame as an `HTMLElement` or nil if the top level frame is active. (Note that frame means iframe)

```crystal
browser.active_frame
# => nil
```

#### switch_to_frame(frame : String | HTMLElement | Nil, focus: true)

Sets the active frame to the provided element or element id. If frame is nil the top level frame will be the active frame.

```crystal
el = browser.find_element(:xpath, "//iframe")
browser.switch_to_frame(el) if el
browser.active_frame
# => <#HTML::Element ...>
```

#### switch_to_frame(by : LocatorStrategy, value, focus = true)

Convenience method for finding an element and switching the active frame to it. See [`find_element`]

#### switch_to_parent_frame

Switches the frame to the parent of the active frame.

```crystal
browser.switch_to_parent_frame
browser.active_frame
# => nil
```

#### cookies

Get's all cookies for the current page as `HTTP::Cookie` instaneces.

```crystal
browser.cookies
# => [<#HTTP::Cookie name: "KBD", value: "8hq2eko2epoijADlkjh9">]
```

#### cookie(name)

Gets a single cookie by name. Retuns nil if the cookie doesn't exist.

```crystal
browser.cookie("KBD")
# => <#HTTP::Cookie name: "KBD", value: "8hq2eko2epoijADlkjh9">
```

#### element_enabled?(el)

Returns true if the provided element is enabled. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_enabled?(el)
# => true
```

#### element_selected?(el)

Returns true if the provided element is selected. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_selected?(el)
# => false
```

#### element_displayed?(el)

Returns true if the provided element is displayed. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_displayed?(el)
# => true
```

#### element_tag_name(el)

Returns the tag name of `el`. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_tag_name(el)
# => "input"
```

#### element_text(el)

Returns the text of `el`. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_text(el)
# => ""
```

#### element_attribute(el, name)

Returns the value of the provided atribute name for `el`. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_attribute(el, "value")
# => "Hello world"
```

#### element_css_property(el, property)

Returns the value of the provided css property for `el`. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_css_property(el, "background-color")
# => "#FFFFFF"
```

#### element_rect(el)

Returns a `ElementRect` instance representing the provided element's position and size within the browser. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.element_rect(el)
# => <#Elementrect x: 123.0, y: 99.0, width: 100.0, height: 80.0>
```

#### click_element(el)

Simulate a click on `el`. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.click_element(el)
```

#### send_keys_to_element(el, *keys)

Sends keys to the provided element. Keys are strings. Keystrokes for special keys such as return anc backspace can be simulated by sending a special unicode character. To make this easier their is a convenience method [`key`]. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.send_keys(input, "Hello world", key(:enter))
```

#### clear_element(el)

Clears a clearable element, such as an `input`. `el` can be a `HTMLElement` or the ID of an element.

```crystal
browser.clear_element(input)
```

#### find_elements(by : LocatorStrategy, value, start_node = nil)

Find all elements on the current page using the specified [`LocatorStrategy`](#locatorstrategy). If a `start_node` is provided it will be used as the container to search inside of. `start_node` can be a `HTMLElement` or the ID of an element.

```crystal
inputs = browser.find_elements(:xpath, "//input")
```

#### find_element(by : LocatorStrategy, value, start_node = nil)

Find a single on the current page using the specified [`LocatorStrategy`](#locatorstrategy). If a `start_node` is provided it will be used as the container to search inside of. `start_node` can be a `HTMLElement` or the ID of an element.

```crystal
input = browser.find_element(:xpath, "//input")
```

#### take_screenshot(**options)

Takes a screenshot of a particular element or the current frame. If the current context is set to `:chrome` the screenshot will be of the entire browser, otherwise the screenshot will be of the current page or provided element.

##### Options

- **element : HTMLElement | String | Nil** - Element to take a screenshot of.
- **hightlights : Array(HTMLElement | String) | Nil** - Array of elements to highlight.
- **full : Bool** - Take a screenshot of the full page.
- **scroll : Bool** - Scroll to the provided element.
- **format : ScreenshotFormat** - Format to export the screenshot as.

```crystal
browser.take_screenshot(
  element = nil,
  highlights = nil,
  full = true,
  scroll = true,
  format = :binary
)
```

#### save_screenshot(file, **options)

Take and save the screenshot to the specified file. Accepts the same options as [`take_screenshot`](#takescreenshotoptions)

#### execute_script(script, args = nil, timeout = @timeout, new_sandbox = true)

Execute JavaScript on the current page. `script` should be a valid JavaScript document as a String. `args` are the arguments to provide, which can be accessed with `arguments[n]` in the script. You can also provide a `timeout` and tell the browser to execute this code in a new sandbox (true by default). If `sandbox` is false the variables from any previously executed script will still exist.

```crystal
browser.execute_script("alert(arguments[0])", ["Hello world"])
```

#### execute_script_async(script, args = nil, timeout = @timeout, new_sandbox = true)

Like [`execute_script`](#executescriptscript-args--nil-timeout--timeout-newsandbox--true), but asynchronous.

```crystal
browser.execute_script_async("alert(arguments[0])", ["Hello world"])
```

#### dismiss_dialog

Dismisses a dialog/alert if there is one. Same as clicking no/cancel.

```crystal
browser.dismiss_dialog
```

#### accept_dialog

Accepts a dialog if there is one. Same as clicking ok/yes.

```crystal
browser.accept_dialog
```

#### get_text_from_dialog

Gets the text from the current dialog if there is one, otherwise returns nil.

```crystal
browser.execute_script("alert(arguments[0])", ["Hello world"])
browser.get_text_from_dialog
# => "Hello world"
```

#### send_keys_to_dialog(*keys)

Sends keys to a dialog. Similar to ['send_keys_to_element`](#sendkeystoelementel-keys).

```crystal
browser.send_keys_to_dialog("My name", key(:enter))
```

#### quit

Closes the browser.

```crystal
browser.quit
```

#### restart

Attempts to restart the browser without closing it. (Not working yet)

```crystal
browser.restart
```

#### clear_pref(pref)

Sets a preference back to it's default value.

#### pref(pref, default_branch = false, value_type = "unspecified")

Gets the value of a user defined preference.

#### set_pref(pref, value, default_branch = false)

Sets a preference to the provided value.

#### set_prefs(prefs, defualt_branch = false)

Accepts a Hash or Array of Tuples and sets each preference (key) to the value.

#### using_prefs(prefs, default_branch = false, &block)

Sets the preferences for the provided block and then resets them afterwards.

## Contributing

1. Fork it ( https://github.com/watzon/marionette/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
