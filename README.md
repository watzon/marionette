# Marionette

Marionette is a Crystal shard that replaces the functionality of Selenium (Firefox only for now) by communicating directly with an instance of the browser. It provides a simple, but powerful API which allows everything from navigation to screenshots to executing JavaScript.

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

## Contributing

1. Fork it ( https://github.com/watzon/marionette/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
