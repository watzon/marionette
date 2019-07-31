# Marionette

Marionette is a Crystal shard that replaces the functionality of Selenium (Firefox only for now) by communicating directly with an instance of the brower. It provides a simple, but powerful API which allows everything from navigation to screenshots to executing JavaScript.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  marionette:
    github: watzon/marionette
```

## Usage

```crystal
require "marionette"

# Marionette.launch launches a Firefox browser and exposes
# it to the block. The browser automatically closes after
# the block is finished.
Marionette.launch do
  goto("https://watzon.tech")
  save_screenshot("watzon-tech.jpg")
end

# Marionette.launch can also be used without a block. This
# method requires that you close the browser yourself.
browser = Marionette.launch
browser.goto("https://watzon.tech")
browser.save_screenshot("watzon-tech.jpg")
browser.quit
```

### Launch options

`Marionette.launch` accepts all the same arguments as `Launcher#launch`. These arguments are:

- **address** - The address that Firefox is listening on. (default: 127.0.0.1)
- **port** - The port that Firefox is listening on. (default: 2828)
- **args** - Arguments to pass to the Firefox process (only if **executable** is not false)
- **profile** - User profile path to launch with (only if **executable** is not false)
- **headless** - Launch browser in headless mode (default: true) (only if **executable** is not false)
- **stdout** - `IO` to use for STDOUT (only if **executable** is not false)
- **stderr** - `IO` to use for STDERR (only if **executable** is not false)
- **accept_insecure_certs** - Open all connections, even if the cert is invalid
- **env** - Environment to pass to `Process` (only if **executable** is not false)
- **default_viewport** - Default size of the browser window (default: {width: 800, height: 600})
- **timeout** - Universal timeout (default: 60000)
- **proxy_configuration** - Proxy config to pass to browser.

### Browser

`Launcher#launch` returns a `Browser` instance which is responible for most of Marionette's functionality. It includes a number of methods which can be found [here](https://watzon.github.io/marionette/Marionette/Browser.html).

## Contributing

1. Fork it ( https://github.com/watzon/marionette/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
