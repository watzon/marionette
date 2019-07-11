# Marionette

Marionette is a Crystal shard which provides a high-level API to control Chrome or Chromium over the dev tools protocol. Marionette runs headless by default, and is capable of downloading a headless chrome instance to run. It can however, be configured to run with a full fledged Chrome or Chromium instance.

This project is an attempt to Crystalize™ [puppeteer](https://github.com/GoogleChrome/puppeteer) and provide a very similar API. Once the API is relatively stable documentation will be added.

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
```

## Contributing

1. Fork it ( https://github.com/watzon/marionette/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
