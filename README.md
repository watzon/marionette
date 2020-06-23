# Marionette

Marionette is a one-size-fits-all approach to WebDriver adapters. It works with most all web driver implementations, including:

- [x] Chrome
- [x] Chromium
- [x] Firefox
- [x] Safari
- [x] Edge
- [x] Internet Explorer
- [x] Opera
- [x] PhantomJS
- [x] Webkit GTK
- [x] WPE Webkit
- [x] Android

## Installation

1. Make sure you have Crystal installed. This is a Crystal project and Crystal is required for usage. If you don't have it installed, see https://crystal-lang.org.

2. Add Marionette to an existing project by adding the dependency to your `shard.yml`

   ```yml
   dependencies:
     marionette:
       github: watzon/marionette
       branch: master
   ```

3. Run `shards install` to download and install Marionette as a dependency.

4. Download and have installed at least one [WebDriver](https://www.w3.org/TR/webdriver/). See the [#webdriver](#WebDriver) section below for links to various downloads.

## WebDriver

WebDriver is a protocol which allows browser implementations to be remote controlled via a common interface. It's because of this functionality that frameworks like Marionette are possible. To use the protocol you first have to have installed one of the many WebDriver implementations, here are some of those:

#### Firefox

GeckoDriver is implemented and supported by Mozilla directly.

- [Downloads](https://github.com/mozilla/geckodriver/releases)
- [Documentation](https://firefox-source-docs.mozilla.org/testing/geckodriver/Support.html)

#### Chrome

ChromeDriver is implemented and supported by the Chromium Project.

- [Downloads](https://sites.google.com/a/chromium.org/chromedriver/downloads)
- [Documentation](https://sites.google.com/a/chromium.org/chromedriver/)

#### Opera

OperaChromiumDriver is implemented and supported by Opera Software.


- [Downloads](https://github.com/operasoftware/operachromiumdriver/releases)
- [Documentation](https://github.com/operasoftware/operachromiumdriver/releases)

#### Safari

SafariDriver is implemented and supported directy by Apple. It comes pre-installed with Safari and Safari Technology Preview.

- [Documentation](https://developer.apple.com/documentation/webkit/about_webdriver_for_safari)

#### Edge

Microsoft is implementing and maintaining the Microsoft Edge WebDriver.

- [Downloads](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/#downloads)
- [Documentation](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver)

#### Internet Explorer

Only version 11 is supported, and it requires additional [configuration](https://github.com/SeleniumHQ/selenium/wiki/InternetExplorerDriver#required-configuration).

**Note:** Marionette specific configuration instructions coming soon.


## Contributing

1. Fork it ( https://github.com/watzon/marionette/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon)  - creator, maintainer
