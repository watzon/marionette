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
Marionette.launch(headless: false) do
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

More docs are coming soon!

## Contributing

1. Fork it ( https://github.com/watzon/marionette/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
